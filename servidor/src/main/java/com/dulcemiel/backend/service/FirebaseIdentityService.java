package com.dulcemiel.backend.service;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.google.firebase.auth.UserRecord;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** Verifica identidad Firebase y resuelve el perfil autorizado en SQL Server. */
@Service
public class FirebaseIdentityService {
    private final JdbcTemplate jdbc;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;
    private final String projectId;
    private final String credentialsFile;
    private volatile FirebaseAuth firebaseAuth;

    public FirebaseIdentityService(
            JdbcTemplate jdbc,
            org.springframework.security.crypto.password.PasswordEncoder passwordEncoder,
            @Value("${app.firebase.project-id:}") String projectId,
            @Value("${app.firebase.credentials-file:}") String credentialsFile) {
        this.jdbc = jdbc;
        this.passwordEncoder = passwordEncoder;
        this.projectId = projectId;
        this.credentialsFile = credentialsFile;
    }

    @Transactional
    public Map<String, Object> resolveUser(String idToken, String requestedName) {
        FirebaseToken token;
        try {
            token = auth().verifyIdToken(idToken, true);
        } catch (FirebaseAuthException ex) {
            throw new InvalidFirebaseTokenException();
        }

        String uid = token.getUid();
        String email = token.getEmail();
        if (email == null || email.isBlank()) throw new InvalidFirebaseTokenException();
        Object firebaseClaim = token.getClaims().get("firebase");
        if (!(firebaseClaim instanceof Map<?, ?> firebaseDetails)
                || !"password".equals(firebaseDetails.get("sign_in_provider"))) {
            throw new InvalidFirebaseTokenException();
        }

        List<Map<String, Object>> linked = jdbc.queryForList(
                "SELECT id, nombre, email, rol, estado FROM usuarios WHERE firebase_uid = ?", uid);
        if (!linked.isEmpty()) return linked.get(0);

        List<Map<String, Object>> byEmail = jdbc.queryForList(
                "SELECT id, nombre, email, rol, estado FROM usuarios WHERE LOWER(email) = LOWER(?)", email);
        if (!byEmail.isEmpty()) {
            if (!Boolean.TRUE.equals(token.getClaims().get("email_verified"))) {
                throw new EmailVerificationRequiredException();
            }
            Map<String, Object> account = byEmail.get(0);
            int id = ((Number) account.get("id")).intValue();
            int rows = jdbc.update("UPDATE usuarios SET firebase_uid = ? WHERE id = ? AND firebase_uid IS NULL", uid, id);
            if (rows != 1) throw new AccountLinkConflictException();
            account.put("firebase_uid", uid);
            return account;
        }

        if (requestedName == null || requestedName.isBlank()) throw new ProfileRequiredException();
        String inertLegacyPassword = passwordEncoder.encode(UUID.randomUUID().toString());
        Integer id = jdbc.queryForObject(
                "INSERT INTO usuarios (nombre, email, password, rol, firebase_uid) VALUES (?, ?, ?, ?, ?); SELECT CAST(SCOPE_IDENTITY() AS INT)",
                Integer.class, requestedName.trim(), email, inertLegacyPassword, "usuario", uid);
        return jdbc.queryForMap("SELECT id, nombre, email, rol, estado FROM usuarios WHERE id = ?", id);
    }

    public String createUser(String email, String password, String displayName) {
        try {
            UserRecord user = auth().createUser(new UserRecord.CreateRequest()
                    .setEmail(email)
                    .setPassword(password)
                    .setDisplayName(displayName));
            return user.getUid();
        } catch (FirebaseAuthException ex) {
            if ("EMAIL_ALREADY_EXISTS".equals(ex.getErrorCode())) throw new EmailAlreadyRegisteredException();
            if ("INVALID_EMAIL".equals(ex.getErrorCode()) || "INVALID_PASSWORD".equals(ex.getErrorCode())) throw new InvalidFirebaseUserException();
            throw new FirebaseUnavailableException();
        }
    }

    public void deleteUser(String uid) {
        try {
            auth().deleteUser(uid);
        } catch (Exception ignored) {
            // El error original del aprovisionamiento SQL es el que debe reportarse.
        }
    }

    private FirebaseAuth auth() {
        FirebaseAuth current = firebaseAuth;
        if (current != null) return current;
        synchronized (this) {
            if (firebaseAuth != null) return firebaseAuth;
            try {
                firebaseAuth = FirebaseAuth.getInstance(firebaseApp());
                return firebaseAuth;
            } catch (FirebaseUnavailableException ex) {
                throw ex;
            } catch (RuntimeException ex) {
                throw new FirebaseUnavailableException();
            }
        }
    }

    public FirebaseApp firebaseApp() {
        return FirebaseApp.getApps().stream().findFirst().orElseGet(() -> {
            try {
                FirebaseOptions.Builder options = FirebaseOptions.builder().setCredentials(credentials());
                if (!projectId.isBlank()) options.setProjectId(projectId);
                return FirebaseApp.initializeApp(options.build());
            } catch (IOException | RuntimeException ex) {
                throw new FirebaseUnavailableException();
            }
        });
    }

    private GoogleCredentials credentials() throws IOException {
        if (credentialsFile == null || credentialsFile.isBlank()) {
            return GoogleCredentials.getApplicationDefault();
        }
        try (InputStream input = Files.newInputStream(Path.of(credentialsFile))) {
            return GoogleCredentials.fromStream(input);
        }
    }

    public static class InvalidFirebaseTokenException extends RuntimeException { }
    public static class EmailVerificationRequiredException extends RuntimeException { }
    public static class AccountLinkConflictException extends RuntimeException { }
    public static class ProfileRequiredException extends RuntimeException { }
    public static class FirebaseUnavailableException extends RuntimeException { }
    public static class EmailAlreadyRegisteredException extends RuntimeException { }
    public static class InvalidFirebaseUserException extends RuntimeException { }
}
