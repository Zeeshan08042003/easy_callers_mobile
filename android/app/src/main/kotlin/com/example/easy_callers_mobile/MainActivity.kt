package com.example.easy_callers_mobile

import android.Manifest
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Handler
import android.provider.CallLog
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.easy_callers/call"
    private lateinit var telephonyManager: TelephonyManager
    private var isCallActive = false
    private var pendingResult: MethodChannel.Result? = null
    private var lastNumber: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        telephonyManager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCall" -> {
                    val number = call.argument<String>("number") ?: ""
                    requestPermissionsAndStartCall(number, result)
                }
                "getLastCallLog" -> getLastCallLog(result)
                "sendBulkWhatsAppMessages" -> {
                    val numbers = call.argument<List<String>>("numbers") ?: listOf()
                    val message = call.argument<String>("message") ?: ""
                    sendBulkWhatsAppMessages(numbers, message)
                    result.success("Bulk WhatsApp messages launched")
                }
                "sendSMS" -> {
                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")
                    sendSMS(number!!, message!!)
                    result.success(null)
                }
                "whatsappCall" -> {
                    val number = call.argument<String>("number")
                    if (number != null) whatsappCall(number)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Request all needed permissions before starting the call */
    private fun requestPermissionsAndStartCall(number: String, result: MethodChannel.Result) {
        val neededPermissions = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            neededPermissions.add(Manifest.permission.CALL_PHONE)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            neededPermissions.add(Manifest.permission.READ_CALL_LOG)
        }
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) != PackageManager.PERMISSION_GRANTED) {
            neededPermissions.add(Manifest.permission.READ_PHONE_STATE)
        }

        if (neededPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, neededPermissions.toTypedArray(), 5001)
            lastNumber = number
            pendingResult = result
        } else {
            startPhoneCall(number, result)
        }
    }

    /** Handle permission result */
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 5001) {
            val allGranted = grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }
            if (allGranted && lastNumber != null && pendingResult != null) {
                startPhoneCall(lastNumber!!, pendingResult!!)
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Required permissions not granted", null)
                pendingResult = null
            }
        }
    }

    /** Start the actual phone call after permissions are granted */
    private fun startPhoneCall(number: String, result: MethodChannel.Result) {
        telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        startCall(number)
        pendingResult = result
    }

    /** Listen for call state changes */
    private val phoneStateListener = object : PhoneStateListener() {
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            when (state) {
                TelephonyManager.CALL_STATE_OFFHOOK -> isCallActive = true
                TelephonyManager.CALL_STATE_IDLE -> {
                    if (isCallActive) {
                        isCallActive = false
                        Handler(mainLooper).postDelayed({
                            if (pendingResult != null) {
                                getLastCallLog(pendingResult!!)
                                pendingResult = null
                            }
                        }, 2000)
                    }
                }
            }
        }
    }

    /** Make the phone call */
    private fun startCall(number: String) {
        val intent = Intent(Intent.ACTION_CALL)
        intent.data = Uri.parse("tel:$number")
        startActivity(intent)
    }

    /** Fetch last call log */
    private fun getLastCallLog(result: MethodChannel.Result) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            result.error("PERMISSION_DENIED", "READ_CALL_LOG permission required", null)
            return
        }

        val cursor = contentResolver.query(
            CallLog.Calls.CONTENT_URI,
            null,
            null,
            null,
            "${CallLog.Calls.DATE} DESC"
        )

        cursor?.use {
            if (it.moveToFirst()) {
                val number = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                val type = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE))
                val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                val duration = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                val formattedDate = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault()).format(Date(date))
                val typeLabel = when (type) {
                    CallLog.Calls.OUTGOING_TYPE -> "Outgoing"
                    CallLog.Calls.INCOMING_TYPE -> "Incoming"
                    CallLog.Calls.MISSED_TYPE -> "Missed"
                    CallLog.Calls.REJECTED_TYPE -> "Rejected"
                    else -> "Unknown"
                }
                val status = if (type == CallLog.Calls.OUTGOING_TYPE && duration == 0L) "Declined or Failed" else "Connected"

                val callDetails = mapOf(
                    "number" to number,
                    "type" to typeLabel,
                    "status" to status,
                    "time" to formattedDate,
                    "duration" to formatDuration(duration)
                )

                result.success(JSONObject(callDetails).toString())
            } else {
                result.success("No call log found")
            }
        } ?: run {
            result.success("No call log data available")
        }
    }

    /** Send a WhatsApp message */
    private fun sendMessageOnWhatsApp(phone: String, message: String) {
        try {
            val uri = Uri.parse("https://wa.me/$phone?text=${Uri.encode(message)}")
            val intent = Intent(Intent.ACTION_VIEW, uri)
            intent.setPackage("com.whatsapp")
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
            } else {
                println("WhatsApp not installed")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    /** Bulk WhatsApp messages */
    private fun sendBulkWhatsAppMessages(numbers: List<String>, message: String) {
        for (number in numbers) {
            sendMessageOnWhatsApp(number, message)
            Thread.sleep(2000)
        }
    }

    /** Send SMS */
    private fun sendSMS(number: String, message: String) {
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("sms:$number"))
        intent.putExtra("sms_body", message)
        startActivity(intent)
    }

    /** Format call duration */
    private fun formatDuration(durationSecs: Long): String {
        val hours = durationSecs / 3600
        val minutes = (durationSecs % 3600) / 60
        val seconds = durationSecs % 60
        return String.format("%02d:%02d:%02d", hours, minutes, seconds)
    }

    /** WhatsApp voice call */
    private fun whatsappCall(number: String) {
        val formattedNumber = number.replace("+", "").replace(" ", "").trim()
        val uri = Uri.parse("whatsapp://call?jid=$formattedNumber@s.whatsapp.net")
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setData(uri)
            setPackage("com.whatsapp")
        }
        try {
            startActivity(intent)
        } catch (e: ActivityNotFoundException) {
            Toast.makeText(this, "WhatsApp not installed", Toast.LENGTH_SHORT).show()
        }
    }
}
