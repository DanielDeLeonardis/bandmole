package com.example.bandmole

import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.ArrayDeque

class MainActivity : FlutterActivity() {
	private val channelName = "bandmole/android_library"
	private val pickRootRequestCode = 4101
	private var pendingPickResult: MethodChannel.Result? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"pickRoot" -> {
						pendingPickResult = result
						startActivityForResult(
							Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
								addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
								addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
								call.argument<String>("initialUri")?.let {
									putExtra("android.provider.extra.INITIAL_URI", Uri.parse(it))
								}
							},
							pickRootRequestCode,
						)
					}
					"scan" -> scan(call.argument<String>("treeUri"), result)
					"read" -> read(call.argument<String>("uri"), result)
					else -> result.notImplemented()
				}
			}
	}

	override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
		super.onActivityResult(requestCode, resultCode, data)
		if (requestCode != pickRootRequestCode) return
		val result = pendingPickResult ?: return
		pendingPickResult = null
		if (resultCode != RESULT_OK || data?.data == null) {
			result.success(null)
			return
		}
		val uri = data.data!!
		try {
			contentResolver.takePersistableUriPermission(
				uri,
				Intent.FLAG_GRANT_READ_URI_PERMISSION,
			)
			result.success(uri.toString())
		} catch (error: SecurityException) {
			result.error("PERMISSION", "Unable to retain library access", error.message)
		}
	}

	private fun scan(treeUriString: String?, result: MethodChannel.Result) {
		if (treeUriString == null) {
			result.error("INVALID_URI", "Missing library URI", null)
			return
		}
		try {
			val rootUri = Uri.parse(treeUriString)
			val rootId = DocumentsContract.getTreeDocumentId(rootUri)
			val queue = ArrayDeque<Pair<String, String>>()
			queue.add(rootId to "")
			val files = mutableListOf<Map<String, String>>()
			while (queue.isNotEmpty()) {
				val (parentId, relativePath) = queue.removeFirst()
				val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(rootUri, parentId)
				contentResolver.query(
					childrenUri,
					arrayOf(DocumentsContract.Document.COLUMN_DOCUMENT_ID, DocumentsContract.Document.COLUMN_DISPLAY_NAME, DocumentsContract.Document.COLUMN_MIME_TYPE),
					null,
					null,
					null,
				)?.use { cursor ->
					val idIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DOCUMENT_ID)
					val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
					val mimeIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_MIME_TYPE)
					while (cursor.moveToNext()) {
						val id = cursor.getString(idIndex)
						val name = cursor.getString(nameIndex)
						val mime = cursor.getString(mimeIndex)
						val childPath = if (relativePath.isEmpty()) name else "$relativePath/$name"
						if (mime == DocumentsContract.Document.MIME_TYPE_DIR) {
							queue.add(id to childPath)
						} else if (supported(name)) {
							files.add(mapOf(
								"uri" to DocumentsContract.buildDocumentUriUsingTree(rootUri, id).toString(),
								"displayPath" to childPath,
							))
						}
					}
				}
			}
			result.success(files.sortedBy { it["displayPath"]!!.lowercase() })
		} catch (error: Exception) {
			result.error("ACCESS", "Unable to read library", error.message)
		}
	}

	private fun read(uriString: String?, result: MethodChannel.Result) {
		if (uriString == null) {
			result.error("INVALID_URI", "Missing document URI", null)
			return
		}
		try {
			contentResolver.openInputStream(Uri.parse(uriString)).use { input ->
				result.success(input?.readBytes())
			}
		} catch (error: Exception) {
			result.error("ACCESS", "Unable to read song", error.message)
		}
	}

	private fun supported(name: String): Boolean {
		val lowerName = name.lowercase()
		return listOf(".cho", ".crd", ".chopro", ".chordpro", ".pro", ".txt")
			.any(lowerName::endsWith)
	}
}
