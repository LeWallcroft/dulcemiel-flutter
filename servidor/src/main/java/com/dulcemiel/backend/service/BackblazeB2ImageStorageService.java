package com.dulcemiel.backend.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

/** Almacena solo los archivos en B2; SQL conserva la ruta y el API construye la URL pública. */
@Service
public class BackblazeB2ImageStorageService {
    private final String endpoint;
    private final String region;
    private final String bucket;
    private final String keyId;
    private final String applicationKey;
    private final String publicBaseUrl;
    private volatile S3Client s3;

    public BackblazeB2ImageStorageService(
            @Value("${app.b2.endpoint:}") String endpoint,
            @Value("${app.b2.region:}") String region,
            @Value("${app.b2.bucket:}") String bucket,
            @Value("${app.b2.key-id:}") String keyId,
            @Value("${app.b2.application-key:}") String applicationKey,
            @Value("${app.b2.public-base-url:}") String publicBaseUrl) {
        this.endpoint = endpoint;
        this.region = region;
        this.bucket = bucket;
        this.keyId = keyId;
        this.applicationKey = applicationKey;
        this.publicBaseUrl = publicBaseUrl;
    }

    /** Sube el archivo y devuelve una clave estable para guardarla en SQL. */
    public String upload(String folder, MultipartFile image) throws IOException {
        if (image == null || image.isEmpty()) return null;
        if (image.getSize() > 5L * 1024 * 1024) {
            throw new InvalidImageException("La imagen no puede superar 5 MB.");
        }
        byte[] bytes = image.getBytes();
        String contentType = detectImageType(bytes);
        if (contentType == null) {
            throw new InvalidImageException("Formato de imagen no compatible. Selecciona una imagen JPG, PNG, WEBP o GIF.");
        }
        String safeFolder = folder == null ? "" : folder.replaceAll("[^a-zA-Z0-9/_-]", "");
        String objectKey = safeFolder + "/" + UUID.randomUUID() + extension(contentType);
        s3().putObject(PutObjectRequest.builder()
                        .bucket(bucket)
                        .key(objectKey)
                        .contentType(contentType)
                        .cacheControl("public, max-age=86400")
                        .build(),
                RequestBody.fromBytes(bytes));
        return objectKey;
    }

    public String publicUrl(String objectKey) {
        if (objectKey == null || objectKey.isBlank()) return null;
        String base = publicBaseUrl == null || publicBaseUrl.isBlank()
                ? defaultPublicBaseUrl()
                : publicBaseUrl.replaceAll("/$", "");
        return base + "/" + encodePath(objectKey);
    }

    public void delete(String objectKey) {
        if (objectKey == null || objectKey.isBlank() || objectKey.equals("null") || objectKey.contains("..")) return;
        try {
            s3().deleteObject(DeleteObjectRequest.builder().bucket(bucket).key(objectKey).build());
        } catch (RuntimeException ignored) {
            // La eliminación del registro SQL no se revierte si falla la limpieza del objeto.
        }
    }

    private S3Client s3() {
        S3Client current = s3;
        if (current != null) return current;
        synchronized (this) {
            if (s3 != null) return s3;
            if (blank(endpoint) || blank(region) || blank(bucket) || blank(keyId) || blank(applicationKey)) {
                throw new IllegalStateException("Configura B2_S3_ENDPOINT, B2_REGION, B2_BUCKET, B2_KEY_ID y B2_APPLICATION_KEY en el servidor.");
            }
            s3 = S3Client.builder()
                    .endpointOverride(URI.create(endpoint))
                    .region(Region.of(region))
                    .credentialsProvider(StaticCredentialsProvider.create(
                            AwsBasicCredentials.create(keyId, applicationKey)))
                    .forcePathStyle(true)
                    .build();
            return s3;
        }
    }

    private String defaultPublicBaseUrl() {
        String host = URI.create(endpoint).getHost();
        if (host == null || !host.startsWith("s3.")) {
            throw new IllegalStateException("B2_S3_ENDPOINT debe tener formato https://s3.<region>.backblazeb2.com");
        }
        return "https://" + bucket + "." + host;
    }

    private static String encodePath(String path) {
        StringBuilder encoded = new StringBuilder();
        for (String segment : path.split("/")) {
            if (!encoded.isEmpty()) encoded.append('/');
            encoded.append(URLEncoder.encode(segment, StandardCharsets.UTF_8).replace("+", "%20"));
        }
        return encoded.toString();
    }

    private static String extension(String contentType) {
        return switch (contentType.toLowerCase()) {
            case "image/jpeg" -> ".jpg";
            case "image/png" -> ".png";
            case "image/webp" -> ".webp";
            case "image/gif" -> ".gif";
            default -> "";
        };
    }

    /** Detecta el formato real del archivo; el MIME declarado por Android puede ser impreciso. */
    private static String detectImageType(byte[] bytes) {
        if (bytes.length >= 3 && (bytes[0] & 0xff) == 0xff && (bytes[1] & 0xff) == 0xd8 && (bytes[2] & 0xff) == 0xff) {
            return "image/jpeg";
        }
        if (bytes.length >= 8 && (bytes[0] & 0xff) == 0x89 && bytes[1] == 'P' && bytes[2] == 'N' && bytes[3] == 'G'
                && (bytes[4] & 0xff) == 0x0d && (bytes[5] & 0xff) == 0x0a && (bytes[6] & 0xff) == 0x1a && (bytes[7] & 0xff) == 0x0a) {
            return "image/png";
        }
        if (bytes.length >= 6 && bytes[0] == 'G' && bytes[1] == 'I' && bytes[2] == 'F'
                && bytes[3] == '8' && (bytes[4] == '7' || bytes[4] == '9') && bytes[5] == 'a') {
            return "image/gif";
        }
        if (bytes.length >= 12 && bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F'
                && bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
            return "image/webp";
        }
        return null;
    }

    public static class InvalidImageException extends RuntimeException {
        public InvalidImageException(String message) { super(message); }
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }
}
