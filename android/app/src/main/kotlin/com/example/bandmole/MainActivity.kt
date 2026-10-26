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
								addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
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
					"writeSong" -> writeSong(call.argument<String>("uri"), call.argument<String>("treeUri"), call.argument<String>("relativePath"), call.argument<String>("text"), result)
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
				data.flags and (Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION),
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

	private fun writeSong(
		uriString: String?,
		treeUriString: String?,
		relativePath: String?,
		text: String?,
		result: MethodChannel.Result,
	) {
		if (text == null) {
			result.error("INVALID_TEXT", "Missing song text", null)
			return
		}
		var createdUri: Uri? = null
		try {
			val destination = if (uriString != null) {
				Uri.parse(uriString)
			} else {
				if (treeUriString == null || relativePath == null) {
					result.error("INVALID_URI", "Missing song destination", null)
					return
				}
				val components = relativePath.split("/")
				if (components.isEmpty() || components.any { it.isEmpty() || it == "." || it == ".." } ||
					!components.last().endsWith(".chopro", ignoreCase = true)) {
					result.error("INVALID_PATH", "Invalid ChordPro destination", null)
					return
				}
				val treeUri = Uri.parse(treeUriString)
				var parentId = DocumentsContract.getTreeDocumentId(treeUri)
				for (folder in components.dropLast(1)) {
					val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
					var foundId: String? = null
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
							if (cursor.getString(nameIndex) == folder &&
								cursor.getString(mimeIndex) == DocumentsContract.Document.MIME_TYPE_DIR) {
								foundId = cursor.getString(idIndex)
								break
							}
						}
					}
					parentId = foundId ?: throw IllegalArgumentException("Song folder is unavailable")
				}
				val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentId)
				contentResolver.query(
					childrenUri,
					arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
					null,
					null,
					null,
				)?.use { cursor ->
					val nameIndex = cursor.getColumnIndexOrThrow(DocumentsContract.Document.COLUMN_DISPLAY_NAME)
					while (cursor.moveToNext()) {
						if (cursor.getString(nameIndex).equals(components.last(), ignoreCase = true)) {
							throw IllegalStateException("Song file already exists")
						}
					}
				}
				val parentUri = DocumentsContract.buildDocumentUriUsingTree(treeUri, parentId)
				DocumentsContract.createDocument(contentResolver, parentUri, "text/plain", components.last())
					?: throw IllegalStateException("Unable to create song")
			}
			if (uriString == null) createdUri = destination
			contentResolver.openOutputStream(destination, "wt").use { output ->
				(output ?: throw IllegalStateException("Unable to open song")).write(text.toByteArray(Charsets.UTF_8))
			}
			result.success(destination.toString())
		} catch (error: Exception) {
			createdUri?.let {
				try { DocumentsContract.deleteDocument(contentResolver, it) } catch (_: Exception) {}
			}
			result.error("WRITE", "Unable to save song", error.message)
		}
	}
	private fun supported(name: String): Boolean {
		val lowerName = name.lowercase()
		return listOf(".cho", ".crd", ".chopro", ".chordpro", ".pro", ".txt")
			.any(lowerName::endsWith)
	}
}
