package com.classattend.downloads;

import android.Manifest;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.content.ContentUris;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public final class ClassAttendDownloadsPlugin implements FlutterPlugin,
        MethodChannel.MethodCallHandler {
    private static final String CHANNEL = "classattend/downloads";
    private static final String RELATIVE_PATH =
            Environment.DIRECTORY_DOWNLOADS + "/ClassAttend/Attendance Reports";

    private Context context;
    private MethodChannel channel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call,
                             @NonNull MethodChannel.Result result) {
        if (!"savePdf".equals(call.method)) {
            result.notImplemented();
            return;
        }

        Object rawBytes = call.argument("bytes");
        String requestedName = call.argument("fileName");
        if (!(rawBytes instanceof byte[]) || requestedName == null || requestedName.trim().isEmpty()) {
            result.error("invalid-arguments", "A PDF file name and contents are required.", null);
            return;
        }

        try {
            byte[] bytes = (byte[]) rawBytes;
            String fileName = normalizePdfName(requestedName);
            String saved = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                    ? saveWithMediaStore(bytes, fileName)
                    : saveLegacy(bytes, fileName);
            result.success(saved);
        } catch (SecurityException error) {
            result.error("permission-denied", "Storage permission is required to save this report.", null);
        } catch (Exception error) {
            result.error("save-failed", "ClassAttend could not save the report to Downloads.", null);
        }
    }

    private String saveWithMediaStore(byte[] bytes, String fileName) throws Exception {
        ContentResolver resolver = context.getContentResolver();
        Uri existing = completedMediaStoreFile(resolver, fileName);
        if (existing != null) return existing.toString();
        deletePendingMediaStoreFile(resolver, fileName);
        String uniqueName = uniqueMediaStoreName(resolver, fileName);
        ContentValues values = new ContentValues();
        values.put(MediaStore.MediaColumns.DISPLAY_NAME, uniqueName);
        values.put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
        values.put(MediaStore.MediaColumns.RELATIVE_PATH, RELATIVE_PATH);
        values.put(MediaStore.MediaColumns.IS_PENDING, 1);

        Uri uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);
        if (uri == null) throw new IllegalStateException("Unable to create the report file.");
        try {
            try (OutputStream output = resolver.openOutputStream(uri)) {
                if (output == null) throw new IllegalStateException("Unable to write the report file.");
                output.write(bytes);
                output.flush();
            }
            ContentValues published = new ContentValues();
            published.put(MediaStore.MediaColumns.IS_PENDING, 0);
            resolver.update(uri, published, null, null);
            return uri.toString();
        } catch (Exception error) {
            resolver.delete(uri, null, null);
            throw error;
        }
    }

    private Uri completedMediaStoreFile(ContentResolver resolver, String name) {
        String[] projection = {MediaStore.MediaColumns._ID};
        String selection = MediaStore.MediaColumns.DISPLAY_NAME + " = ? AND "
                + MediaStore.MediaColumns.RELATIVE_PATH + " = ? AND "
                + MediaStore.MediaColumns.IS_PENDING + " = 0";
        try (Cursor cursor = resolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                new String[]{name, RELATIVE_PATH + "/"},
                null)) {
            if (cursor == null || !cursor.moveToFirst()) return null;
            return ContentUris.withAppendedId(
                    MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    cursor.getLong(0));
        }
    }

    private void deletePendingMediaStoreFile(ContentResolver resolver, String name) {
        String selection = MediaStore.MediaColumns.DISPLAY_NAME + " = ? AND "
                + MediaStore.MediaColumns.RELATIVE_PATH + " = ? AND "
                + MediaStore.MediaColumns.IS_PENDING + " = 1";
        resolver.delete(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                selection,
                new String[]{name, RELATIVE_PATH + "/"});
    }

    private String uniqueMediaStoreName(ContentResolver resolver, String requestedName) {
        String stem = requestedName.substring(0, requestedName.length() - 4);
        String candidate = requestedName;
        int suffix = 2;
        while (mediaStoreNameExists(resolver, candidate)) {
            candidate = stem + " (" + suffix++ + ").pdf";
        }
        return candidate;
    }

    private boolean mediaStoreNameExists(ContentResolver resolver, String name) {
        String[] projection = {MediaStore.MediaColumns._ID};
        String selection = MediaStore.MediaColumns.DISPLAY_NAME + " = ? AND "
                + MediaStore.MediaColumns.RELATIVE_PATH + " = ?";
        try (Cursor cursor = resolver.query(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                projection,
                selection,
                new String[]{name, RELATIVE_PATH + "/"},
                null)) {
            return cursor != null && cursor.moveToFirst();
        }
    }

    private String saveLegacy(byte[] bytes, String fileName) throws Exception {
        if (context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE)
                != PackageManager.PERMISSION_GRANTED) {
            throw new SecurityException("Storage permission is not granted.");
        }
        File folder = new File(
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS),
                "ClassAttend/Attendance Reports");
        if (!folder.exists() && !folder.mkdirs()) {
            throw new IllegalStateException("Unable to create the report folder.");
        }
        String stem = fileName.substring(0, fileName.length() - 4);
        File target = new File(folder, fileName);
        if (target.exists()) return target.getAbsolutePath();
        int suffix = 2;
        while (target.exists()) {
            target = new File(folder, stem + " (" + suffix++ + ").pdf");
        }
        try (FileOutputStream output = new FileOutputStream(target)) {
            output.write(bytes);
            output.flush();
        }
        return target.getAbsolutePath();
    }

    private String normalizePdfName(String name) {
        String safe = name.replaceAll("[^A-Za-z0-9._ -]", "_").trim();
        return safe.toLowerCase().endsWith(".pdf") ? safe : safe + ".pdf";
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        channel = null;
        context = null;
    }
}
