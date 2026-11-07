package com.dulcemiel.backend.service;

import com.dulcemiel.backend.model.AuthUser;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Date;

@Service
public class JwtService {
    private final SecretKey key;
    private final long expirationMs;
    private final JdbcTemplate jdbc;

    public JwtService(@Value("${app.jwt.secret}") String secret, @Value("${app.jwt.expiration-ms}") long expirationMs, JdbcTemplate jdbc) {
        String normalized = secret.length() >= 32 ? secret : secret + "0".repeat(32 - secret.length());
        this.key = Keys.hmacShaKeyFor(normalized.getBytes(StandardCharsets.UTF_8));
        this.expirationMs = expirationMs;
        this.jdbc = jdbc;
    }

    public String generateToken(Integer userId, String email, String role) {
        Instant now = Instant.now();
        return Jwts.builder()
                .claim("userId", userId)
                .claim("email", email)
                .claim("role", role)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusMillis(expirationMs)))
                .signWith(key)
                .compact();
    }

    public AuthUser parse(String authorizationHeader) {
        if (authorizationHeader == null || !authorizationHeader.startsWith("Bearer ")) {
            return null;
        }
        try {
            var claims = Jwts.parser().verifyWith(key).build()
                    .parseSignedClaims(authorizationHeader.substring(7))
                    .getPayload();
            Number userId = claims.get("userId", Number.class);
            String tokenRole = claims.get("role", String.class);
            var accounts = jdbc.queryForList("SELECT rol, estado FROM usuarios WHERE id = ?", userId.intValue());
            if (accounts.isEmpty()) return null;
            var account = accounts.get(0);
            if (!"activo".equals(account.get("estado")) || !tokenRole.equals(account.get("rol"))) return null;
            return new AuthUser(userId.intValue(), claims.get("email", String.class), tokenRole);
        } catch (Exception ignored) {
            return null;
        }
    }
}
