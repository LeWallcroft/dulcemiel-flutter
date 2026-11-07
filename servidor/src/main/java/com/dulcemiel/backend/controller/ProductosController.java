package com.dulcemiel.backend.controller;

import com.dulcemiel.backend.model.AuthUser;
import com.dulcemiel.backend.service.ImageUrlService;
import com.dulcemiel.backend.service.BackblazeB2ImageStorageService;
import com.dulcemiel.backend.service.JwtService;
import com.dulcemiel.backend.service.ResponseService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/productos")
public class ProductosController {
    private final JdbcTemplate jdbc;
    private final JwtService jwt;
    private final ImageUrlService images;
    private final ResponseService responses;
    private final BackblazeB2ImageStorageService storage;

    public ProductosController(JdbcTemplate jdbc, JwtService jwt, ImageUrlService images, ResponseService responses, BackblazeB2ImageStorageService storage) {
        this.jdbc = jdbc;
        this.jwt = jwt;
        this.images = images;
        this.responses = responses;
        this.storage = storage;
    }

    @GetMapping
    ResponseEntity<Map<String, Object>> list(HttpServletRequest request) {
        var rows = jdbc.queryForList("SELECT id, nombre, descripcion, precio, stock, categoria, estado, fecha_actualizacion, imagen_url, imagen_storage_key, informacion_ods12, meta_ods12, CAST(CASE WHEN imagen_data IS NULL AND imagen_url IS NULL AND imagen_storage_key IS NULL THEN 0 ELSE 1 END AS BIT) AS tiene_imagen FROM productos WHERE estado = 'disponible'");
        return responses.ok("success", true, "data", rows.stream().map(row -> productResponse(request, row)).toList());
    }

    @GetMapping("/admin/todos")
    ResponseEntity<Map<String, Object>> listAll(@RequestHeader(value = "Authorization", required = false) String authorization, HttpServletRequest request) {
        if (!isAdmin(authorization)) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        var rows = jdbc.queryForList("SELECT id, nombre, descripcion, precio, stock, categoria, estado, fecha_actualizacion, imagen_url, imagen_storage_key, informacion_ods12, meta_ods12, CAST(CASE WHEN imagen_data IS NULL AND imagen_url IS NULL AND imagen_storage_key IS NULL THEN 0 ELSE 1 END AS BIT) AS tiene_imagen FROM productos ORDER BY fecha_creacion DESC");
        return responses.ok("success", true, "data", rows.stream().map(row -> productResponse(request, row)).toList());
    }

    @GetMapping("/{id}")
    ResponseEntity<Map<String, Object>> get(@PathVariable Integer id, HttpServletRequest request) {
        var rows = jdbc.queryForList("SELECT id, nombre, descripcion, precio, stock, categoria, estado, fecha_creacion, fecha_actualizacion, imagen_url, imagen_storage_key, informacion_ods12, meta_ods12, CAST(CASE WHEN imagen_data IS NULL AND imagen_url IS NULL AND imagen_storage_key IS NULL THEN 0 ELSE 1 END AS BIT) AS tiene_imagen FROM productos WHERE id = ?", id);
        if (rows.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Producto no encontrado");
        return responses.ok("success", true, "data", productResponse(request, rows.get(0)));
    }

    @PostMapping
    ResponseEntity<Map<String, Object>> create(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @RequestParam Map<String, String> body,
                                               @RequestParam(value = "imagen", required = false) MultipartFile image) throws IOException {
        if (!isAdmin(authorization)) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        String error = validateProduct(body.get("nombre"), body.get("precio"), body.get("stock"), "disponible");
        if (error != null) return responses.error(HttpStatus.BAD_REQUEST, error);
        String optionError = validatePackaging(body);
        if (optionError != null) return responses.error(HttpStatus.BAD_REQUEST, optionError);
        String imageKey;
        try {
            imageKey = storage.upload("productos", image);
        } catch (BackblazeB2ImageStorageService.InvalidImageException exception) {
            return responses.error(HttpStatus.BAD_REQUEST, exception.getMessage());
        }
        Integer id = jdbc.queryForObject("""
                INSERT INTO productos (nombre, descripcion, precio, stock, categoria, imagen_storage_key, informacion_ods12, meta_ods12)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?); SELECT CAST(SCOPE_IDENTITY() AS INT)
                """, Integer.class, body.get("nombre"), emptyToNull(body.get("descripcion")), body.get("precio"), body.get("stock"), emptyToNull(body.get("categoria")), imageKey,
                emptyToNull(body.get("informacion_ods12")), validTarget(body.get("meta_ods12")));
        savePackagingOptions(id, body);
        return responses.created("success", true, "message", "Producto creado exitosamente", "productId", id);
    }

    @PutMapping("/{id}")
    ResponseEntity<Map<String, Object>> update(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @PathVariable Integer id,
                                               @RequestParam Map<String, String> body,
                                               @RequestParam(value = "imagen", required = false) MultipartFile image) throws IOException {
        if (!isAdmin(authorization)) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        String estado = body.getOrDefault("estado", "disponible");
        String error = validateProduct(body.get("nombre"), body.get("precio"), body.get("stock"), estado);
        if (error != null) return responses.error(HttpStatus.BAD_REQUEST, error);
        String optionError = validatePackaging(body);
        if (optionError != null) return responses.error(HttpStatus.BAD_REQUEST, optionError);
        var current = jdbc.queryForList("SELECT imagen_storage_key FROM productos WHERE id = ?", id);
        if (current.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Producto no encontrado");
        if (image == null || image.isEmpty()) {
            jdbc.update("UPDATE productos SET nombre = ?, descripcion = ?, precio = ?, stock = ?, categoria = ?, estado = ?, informacion_ods12 = ?, meta_ods12 = ? WHERE id = ?",
                    body.get("nombre"), emptyToNull(body.get("descripcion")), body.get("precio"), body.get("stock"), emptyToNull(body.get("categoria")), estado,
                    emptyToNull(body.get("informacion_ods12")), validTarget(body.get("meta_ods12")), id);
        } else {
            String imageKey;
            try {
                imageKey = storage.upload("productos", image);
            } catch (BackblazeB2ImageStorageService.InvalidImageException exception) {
                return responses.error(HttpStatus.BAD_REQUEST, exception.getMessage());
            }
            jdbc.update("UPDATE productos SET nombre = ?, descripcion = ?, precio = ?, stock = ?, categoria = ?, estado = ?, informacion_ods12 = ?, meta_ods12 = ?, imagen_storage_key = ?, imagen_url = NULL, imagen_data = NULL, imagen_mime = NULL, imagen_nombre = NULL WHERE id = ?",
                    body.get("nombre"), emptyToNull(body.get("descripcion")), body.get("precio"), body.get("stock"), emptyToNull(body.get("categoria")), estado,
                    emptyToNull(body.get("informacion_ods12")), validTarget(body.get("meta_ods12")),
                    imageKey, id);
            storage.delete(String.valueOf(current.get(0).get("imagen_storage_key")));
        }
        savePackagingOptions(id, body);
        return responses.ok("success", true, "message", "Producto actualizado exitosamente");
    }

    @DeleteMapping("/{id}")
    ResponseEntity<Map<String, Object>> delete(@RequestHeader(value = "Authorization", required = false) String authorization, @PathVariable Integer id) {
        if (!isAdmin(authorization)) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        Number assigned = jdbc.queryForObject("SELECT COUNT(*) FROM detalles_pedido WHERE producto_id = ?", Number.class, id);
        if (assigned != null && assigned.intValue() > 0) {
            return responses.error(HttpStatus.CONFLICT, "No se puede eliminar este producto porque ya esta asignado a uno o mas pedidos. Cambia su estado a discontinuado para ocultarlo del catalogo.");
        }
        var current = jdbc.queryForList("SELECT imagen_storage_key FROM productos WHERE id = ?", id);
        int rows = jdbc.update("DELETE FROM productos WHERE id = ?", id);
        if (rows == 0) return responses.error(HttpStatus.NOT_FOUND, "Producto no encontrado");
        if (!current.isEmpty()) storage.delete(String.valueOf(current.get(0).get("imagen_storage_key")));
        return responses.ok("success", true, "message", "Producto eliminado exitosamente");
    }

    private boolean isAdmin(String authorization) {
        AuthUser user = jwt.parse(authorization);
        return user != null && user.canAdmin();
    }

    private static String validateProduct(String nombre, String precio, String stock, String estado) {
        if (nombre == null || nombre.trim().isEmpty()) return "El nombre del producto es requerido";
        if (precio == null || precio.isBlank() || Double.parseDouble(precio) < 0) return "El precio es requerido y debe ser mayor o igual a 0";
        if (stock == null || stock.isBlank() || Integer.parseInt(stock) < 0) return "El stock es requerido y debe ser mayor o igual a 0";
        if (!List.of("disponible", "agotado", "discontinuado").contains(estado)) return "El estado del producto no es valido";
        return null;
    }

    private static Object emptyToNull(String value) {
        return value == null || value.isBlank() ? null : value;
    }

    private Map<String, Object> productResponse(HttpServletRequest request, Map<String, Object> row) {
        Map<String, Object> response = new HashMap<>(images.product(request, row));
        Integer productId = ((Number) row.get("id")).intValue();
        response.put("opciones_envase", jdbc.queryForList("""
                SELECT id, codigo, nombre, descripcion, costo_extra, activo
                FROM opciones_envase_producto WHERE producto_id = ? AND activo = 1 ORDER BY id
                """, productId));
        response.put("informacion_ods12", row.get("informacion_ods12"));
        response.put("meta_ods12", row.get("meta_ods12"));
        return response;
    }

    private void savePackagingOptions(Integer productId, Map<String, String> body) {
        upsertOption(productId, "convencional", "Envase convencional",
                body.getOrDefault("descripcion_envase_convencional", "Presentación convencional del producto."), BigDecimal.ZERO, true);
        if (body.containsKey("frasco_vidrio_activo")) {
            upsertOption(productId, "vidrio_dulcemiel", "Comprar frasco de vidrio",
                    body.getOrDefault("descripcion_envase_vidrio", "Frasco de vidrio suministrado por Dulce Miel."),
                    new BigDecimal(body.getOrDefault("costo_envase_vidrio", "0")), Boolean.parseBoolean(body.get("frasco_vidrio_activo")));
            upsertOption(productId, "frasco_cliente", "Usar mi frasco de vidrio",
                    body.getOrDefault("descripcion_envase_propio", "Envía tu frasco de vidrio limpio para recargarlo."), BigDecimal.ZERO,
                    Boolean.parseBoolean(body.get("frasco_cliente_activo")));
        }
    }

    private void upsertOption(Integer productId, String code, String name, String description, BigDecimal cost, boolean active) {
        int rows = jdbc.update("UPDATE opciones_envase_producto SET nombre = ?, descripcion = ?, costo_extra = ?, activo = ? WHERE producto_id = ? AND codigo = ?",
                name, description, cost, active, productId, code);
        if (rows == 0) jdbc.update("INSERT INTO opciones_envase_producto (producto_id, codigo, nombre, descripcion, costo_extra, activo) VALUES (?, ?, ?, ?, ?, ?)",
                productId, code, name, description, cost, active);
    }

    private static String validatePackaging(Map<String, String> body) {
        if (!body.containsKey("frasco_vidrio_activo")) return null;
        try {
            BigDecimal cost = new BigDecimal(body.getOrDefault("costo_envase_vidrio", "0"));
            if (cost.signum() < 0) return "El costo del frasco de vidrio no puede ser negativo.";
        } catch (NumberFormatException exception) {
            return "Ingresa un costo válido para el frasco de vidrio.";
        }
        if (Boolean.parseBoolean(body.get("frasco_vidrio_activo")) && blank(body.get("descripcion_envase_vidrio"))) {
            return "Describe el frasco de vidrio que proporciona Dulce Miel.";
        }
        if (Boolean.parseBoolean(body.get("frasco_cliente_activo")) && blank(body.get("descripcion_envase_propio"))) {
            return "Describe las condiciones para enviar el frasco propio.";
        }
        return null;
    }

    private static String validTarget(String target) {
        return List.of("12.5", "12.8").contains(target) ? target : null;
    }

    private static boolean blank(String value) {
        return value == null || value.isBlank();
    }

}
