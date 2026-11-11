package com.dulcemiel.backend.controller;

import com.dulcemiel.backend.model.AuthUser;
import com.dulcemiel.backend.service.AuthSupport;
import com.dulcemiel.backend.service.ImageUrlService;
import com.dulcemiel.backend.service.ResponseService;
import com.dulcemiel.backend.service.BackblazeB2ImageStorageService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/pedidos")
public class PedidosController {
    private final JdbcTemplate jdbc;
    private final AuthSupport auth;
    private final ImageUrlService images;
    private final ResponseService responses;
    private final BackblazeB2ImageStorageService storage;

    public PedidosController(JdbcTemplate jdbc, AuthSupport auth, ImageUrlService images, ResponseService responses,
                             BackblazeB2ImageStorageService storage) {
        this.jdbc = jdbc;
        this.auth = auth;
        this.images = images;
        this.responses = responses;
        this.storage = storage;
    }

    @PostMapping
    @Transactional
    ResponseEntity<Map<String, Object>> create(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @RequestBody Map<String, Object> body) {
        AuthUser user = auth.user(authorization);
        if (user == null) return responses.error(HttpStatus.UNAUTHORIZED, "Token no proporcionado");
        String validation = validateDelivery(body);
        if (validation != null) return responses.error(HttpStatus.BAD_REQUEST, validation);

        var items = jdbc.queryForList("""
                SELECT c.id, c.producto_id, c.cantidad, c.precio_unitario, c.costo_envase_unitario,
                       p.stock, p.nombre, oe.codigo AS envase_codigo, oe.nombre AS envase_nombre,
                       oe.descripcion AS envase_descripcion
                FROM carrito c JOIN productos p ON c.producto_id = p.id
                JOIN opciones_envase_producto oe ON oe.id = c.opcion_envase_id
                WHERE c.usuario_id = ?
                """, user.userId());
        if (items.isEmpty()) return responses.error(HttpStatus.BAD_REQUEST, "El carrito está vacío");
        for (Map<String, Object> item : items) {
            if (integer(item.get("stock")) < integer(item.get("cantidad"))) {
                return responses.error(HttpStatus.BAD_REQUEST, "Stock insuficiente para " + item.get("nombre"));
            }
        }

        BigDecimal total = items.stream()
                .map(item -> decimal(item.get("cantidad")).multiply(decimal(item.get("precio_unitario")).add(decimal(item.get("costo_envase_unitario")))))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        boolean hasCustomerJar = items.stream().anyMatch(item -> "frasco_cliente".equals(item.get("envase_codigo")));
        int expectedJars = items.stream().filter(item -> "frasco_cliente".equals(item.get("envase_codigo")))
                .mapToInt(item -> integer(item.get("cantidad"))).sum();
        Map<String, Object> jarDestination = hasCustomerJar
                ? jdbc.queryForList("SELECT direccion_envases, receptor_envases, telefono_envases FROM configuracion_sitio WHERE id = 1").stream().findFirst().orElse(Map.of())
                : Map.of();
        String orderNumber = "PED-" + System.currentTimeMillis();
        Integer orderId = jdbc.queryForObject("""
                INSERT INTO pedidos (
                  usuario_id, numero_pedido, total, contacto_nombre, contacto_telefono,
                  contacto_email, direccion_entrega, distrito, referencia, notas, estado,
                  tiene_envase_cliente, cantidad_envases_cliente, envase_destino, envase_receptor, envase_telefono,
                  direccion_entrega_lat, direccion_entrega_lng
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?); SELECT CAST(SCOPE_IDENTITY() AS INT)
                """, Integer.class, user.userId(), orderNumber, total, body.get("contacto_nombre"), body.get("contacto_telefono"),
                emptyToNull(body.get("contacto_email")), body.get("direccion_entrega"), body.get("distrito"),
                emptyToNull(body.get("referencia")), emptyToNull(body.get("notas")), hasCustomerJar ? "esperando_envase" : "pendiente",
                hasCustomerJar, expectedJars, jarDestination.get("direccion_envases"), jarDestination.get("receptor_envases"), jarDestination.get("telefono_envases"),
                decimalOrNull(body.get("direccion_entrega_lat")), decimalOrNull(body.get("direccion_entrega_lng")));

        for (Map<String, Object> item : items) {
            BigDecimal unitPrice = decimal(item.get("precio_unitario"));
            BigDecimal packageCost = decimal(item.get("costo_envase_unitario"));
            BigDecimal subtotal = decimal(item.get("cantidad")).multiply(unitPrice.add(packageCost));
            jdbc.update("""
                    INSERT INTO detalles_pedido (pedido_id, producto_id, cantidad, precio_unitario, subtotal,
                      envase_codigo, envase_nombre, envase_descripcion, costo_envase_unitario)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """, orderId, item.get("producto_id"), item.get("cantidad"), unitPrice, subtotal,
                    item.get("envase_codigo"), item.get("envase_nombre"), item.get("envase_descripcion"), packageCost);
            jdbc.update("UPDATE productos SET stock = stock - ?, estado = CASE WHEN stock - ? <= 0 THEN 'agotado' ELSE estado END WHERE id = ?",
                    item.get("cantidad"), item.get("cantidad"), item.get("producto_id"));
        }
        jdbc.update("DELETE FROM carrito WHERE usuario_id = ?", user.userId());
        return responses.created("success", true, "message", "Pedido creado exitosamente",
                "pedido", responses.body("id", orderId, "numero_pedido", orderNumber, "total", total.setScale(2).toString(),
                        "estado", hasCustomerJar ? "esperando_envase" : "pendiente", "tiene_envase_cliente", hasCustomerJar));
    }

    @GetMapping
    ResponseEntity<Map<String, Object>> userOrders(@RequestHeader(value = "Authorization", required = false) String authorization) {
        AuthUser user = auth.user(authorization);
        if (user == null) return responses.error(HttpStatus.UNAUTHORIZED, "Token no proporcionado");
        var rows = jdbc.queryForList("""
                SELECT id, numero_pedido, total, estado, fecha_pedido, fecha_entrega,
                       contacto_nombre, contacto_telefono, contacto_email, direccion_entrega, direccion_entrega_lat, direccion_entrega_lng, distrito, referencia, notas,
                       tiene_envase_cliente, cantidad_envases_cliente, envase_envio_agencia, envase_envio_guia,
                       envase_envio_costo, envase_envio_boleta_key, envase_recibido_fecha,
                       envio_pedido_agencia, envio_pedido_guia, envio_pedido_costo, envio_pedido_boleta_key
                FROM pedidos WHERE usuario_id = ? ORDER BY fecha_pedido DESC
                """, user.userId());
        return responses.ok("success", true, "data", rows.stream().map(this::shipmentUrls).toList());
    }

    @GetMapping("/admin/todos")
    ResponseEntity<Map<String, Object>> allOrders(@RequestHeader(value = "Authorization", required = false) String authorization) {
        if (auth.admin(authorization) == null) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        var rows = jdbc.queryForList("""
                SELECT p.id, p.numero_pedido, p.total, p.estado, p.fecha_pedido, p.fecha_entrega,
                       p.contacto_nombre, p.contacto_telefono, p.contacto_email,
                       p.direccion_entrega, p.direccion_entrega_lat, p.direccion_entrega_lng, p.distrito, p.referencia, p.notas,
                       p.tiene_envase_cliente, p.cantidad_envases_cliente, p.envase_envio_agencia, p.envase_envio_guia,
                       p.envase_envio_costo, p.envase_envio_boleta_key, p.envase_recibido_fecha,
                       p.envio_pedido_agencia, p.envio_pedido_guia, p.envio_pedido_costo, p.envio_pedido_boleta_key,
                       u.nombre, u.email
                FROM pedidos p JOIN usuarios u ON p.usuario_id = u.id
                ORDER BY p.fecha_pedido DESC
                """);
        return responses.ok("success", true, "data", rows.stream().map(this::shipmentUrls).toList());
    }

    @GetMapping("/{pedidoId}")
    ResponseEntity<Map<String, Object>> detail(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @PathVariable Integer pedidoId,
                                               HttpServletRequest request) {
        AuthUser user = auth.user(authorization);
        if (user == null) return responses.error(HttpStatus.UNAUTHORIZED, "Token no proporcionado");
        boolean admin = user.canAdmin();
        var pedidos = admin
                ? jdbc.queryForList("SELECT * FROM pedidos WHERE id = ?", pedidoId)
                : jdbc.queryForList("SELECT * FROM pedidos WHERE id = ? AND usuario_id = ?", pedidoId, user.userId());
        if (pedidos.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Pedido no encontrado");
        var detalles = jdbc.queryForList("""
                SELECT dp.id, dp.producto_id, p.nombre, dp.cantidad, dp.precio_unitario, dp.subtotal,
                       dp.envase_nombre, dp.costo_envase_unitario,
                       p.imagen_url, p.imagen_storage_key,
                       CAST(CASE WHEN p.imagen_data IS NULL AND p.imagen_url IS NULL AND p.imagen_storage_key IS NULL THEN 0 ELSE 1 END AS BIT) AS tiene_imagen
                FROM detalles_pedido dp JOIN productos p ON dp.producto_id = p.id
                WHERE dp.pedido_id = ?
                """, pedidoId);
        Map<String, Object> order = new java.util.HashMap<>(pedidos.get(0));
        order.put("envase_envio_boleta_url", storage.publicUrl(string(order.get("envase_envio_boleta_key"))));
        order.put("envio_pedido_boleta_url", storage.publicUrl(string(order.get("envio_pedido_boleta_key"))));
        order.remove("envase_envio_boleta_key");
        order.remove("envio_pedido_boleta_key");
        return responses.ok("success", true, "pedido", order,
                "detalles", detalles.stream().map(row -> images.product(request, row)).toList());
    }

    @PutMapping("/{pedidoId}")
    ResponseEntity<Map<String, Object>> updateStatus(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                     @PathVariable Integer pedidoId,
                                                     @RequestBody Map<String, Object> body) {
        if (auth.admin(authorization) == null) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        String estado = String.valueOf(body.getOrDefault("estado", ""));
        if (estado.isBlank()) return responses.error(HttpStatus.BAD_REQUEST, "Estado es requerido");
        if (!List.of("pendiente", "procesando", "entregado", "cancelado").contains(estado)) {
            return responses.error(HttpStatus.BAD_REQUEST, "Estado inválido");
        }
        if ("procesando".equals(estado)) {
            var order = jdbc.queryForList("SELECT tiene_envase_cliente, envase_envio_agencia, envase_envio_guia, envase_recibido_fecha FROM pedidos WHERE id = ?", pedidoId);
            if (order.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Pedido no encontrado");
            Map<String, Object> row = order.get(0);
            if (Boolean.TRUE.equals(row.get("tiene_envase_cliente")) &&
                    (row.get("envase_envio_agencia") == null || row.get("envase_envio_guia") == null)) {
                return responses.error(HttpStatus.CONFLICT, "El cliente aún no registra el envío del frasco.");
            }
            jdbc.update("UPDATE pedidos SET estado = ?, envase_recibido_fecha = CASE WHEN tiene_envase_cliente = 1 AND envase_recibido_fecha IS NULL THEN SYSUTCDATETIME() ELSE envase_recibido_fecha END WHERE id = ?", estado, pedidoId);
            return responses.ok("success", true, "message", "Recepción del frasco confirmada y pedido en preparación.");
        }
        int rows = jdbc.update("UPDATE pedidos SET estado = ? WHERE id = ?", estado, pedidoId);
        if (rows == 0) return responses.error(HttpStatus.NOT_FOUND, "Pedido no encontrado");
        return responses.ok("success", true, "message", "Estado del pedido actualizado");
    }

    @PutMapping(value = "/{pedidoId}/envase", consumes = "multipart/form-data")
    ResponseEntity<Map<String, Object>> submitCustomerJarShipment(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @PathVariable Integer pedidoId,
            @RequestParam Map<String, String> fields,
            @RequestParam(value = "boleta", required = false) MultipartFile receipt) throws java.io.IOException {
        AuthUser user = auth.user(authorization);
        if (user == null) return responses.error(HttpStatus.UNAUTHORIZED, "Token no proporcionado");
        if (blank(fields.get("agencia")) || blank(fields.get("guia")) || blank(fields.get("costo"))) {
            return responses.error(HttpStatus.BAD_REQUEST, "Completa la agencia, la guía y el costo del envío del frasco.");
        }
        if (receipt == null || receipt.isEmpty()) return responses.error(HttpStatus.BAD_REQUEST, "Adjunta la boleta del envío del frasco.");
        BigDecimal cost;
        try { cost = new BigDecimal(fields.get("costo")); }
        catch (NumberFormatException exception) { return responses.error(HttpStatus.BAD_REQUEST, "El costo del envío no es válido."); }
        if (cost.signum() < 0) return responses.error(HttpStatus.BAD_REQUEST, "El costo del envío no puede ser negativo.");
        var rows = jdbc.queryForList("SELECT estado, tiene_envase_cliente FROM pedidos WHERE id = ? AND usuario_id = ?", pedidoId, user.userId());
        if (rows.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Pedido no encontrado.");
        if (!Boolean.TRUE.equals(rows.get(0).get("tiene_envase_cliente")) || !"esperando_envase".equals(rows.get(0).get("estado"))) {
            return responses.error(HttpStatus.CONFLICT, "Este pedido no está esperando un frasco propio.");
        }
        String receiptKey;
        try { receiptKey = storage.upload("boletas/envases", receipt); }
        catch (BackblazeB2ImageStorageService.InvalidImageException exception) {
            return responses.error(HttpStatus.BAD_REQUEST, exception.getMessage());
        }
        jdbc.update("UPDATE pedidos SET envase_envio_agencia = ?, envase_envio_guia = ?, envase_envio_costo = ?, envase_envio_boleta_key = ? WHERE id = ? AND usuario_id = ?",
                fields.get("agencia").trim(), fields.get("guia").trim(), cost, receiptKey, pedidoId, user.userId());
        return responses.ok("success", true, "message", "Datos y boleta del envío del frasco guardados.");
    }

    @PutMapping(value = "/{pedidoId}/envio", consumes = "multipart/form-data")
    ResponseEntity<Map<String, Object>> submitOutboundShipment(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @PathVariable Integer pedidoId,
            @RequestParam Map<String, String> fields,
            @RequestParam(value = "boleta", required = false) MultipartFile receipt) throws java.io.IOException {
        if (auth.admin(authorization) == null) return responses.error(HttpStatus.FORBIDDEN, "Acceso denegado. Se requieren permisos de administrador");
        if (blank(fields.get("agencia")) || blank(fields.get("guia")) || blank(fields.get("costo"))) {
            return responses.error(HttpStatus.BAD_REQUEST, "Completa la agencia, la guía y el costo del envío del pedido.");
        }
        if (receipt == null || receipt.isEmpty()) return responses.error(HttpStatus.BAD_REQUEST, "Adjunta la boleta de envío del pedido.");
        BigDecimal cost;
        try { cost = new BigDecimal(fields.get("costo")); }
        catch (NumberFormatException exception) { return responses.error(HttpStatus.BAD_REQUEST, "El costo del envío no es válido."); }
        if (cost.signum() < 0) return responses.error(HttpStatus.BAD_REQUEST, "El costo del envío no puede ser negativo.");
        var rows = jdbc.queryForList("SELECT estado, tiene_envase_cliente, envase_recibido_fecha FROM pedidos WHERE id = ?", pedidoId);
        if (rows.isEmpty()) return responses.error(HttpStatus.NOT_FOUND, "Pedido no encontrado.");
        Map<String, Object> order = rows.get(0);
        if (!List.of("procesando", "pendiente").contains(order.get("estado"))) return responses.error(HttpStatus.CONFLICT, "El pedido no está listo para registrar el envío.");
        if (Boolean.TRUE.equals(order.get("tiene_envase_cliente")) && order.get("envase_recibido_fecha") == null) {
            return responses.error(HttpStatus.CONFLICT, "Confirma la recepción del frasco antes de enviar el pedido.");
        }
        String receiptKey;
        try { receiptKey = storage.upload("boletas/pedidos", receipt); }
        catch (BackblazeB2ImageStorageService.InvalidImageException exception) {
            return responses.error(HttpStatus.BAD_REQUEST, exception.getMessage());
        }
        jdbc.update("UPDATE pedidos SET estado = 'enviado', envio_pedido_agencia = ?, envio_pedido_guia = ?, envio_pedido_costo = ?, envio_pedido_boleta_key = ? WHERE id = ?",
                fields.get("agencia").trim(), fields.get("guia").trim(), cost, receiptKey, pedidoId);
        return responses.ok("success", true, "message", "Envío registrado y pedido marcado como enviado.");
    }

    private static String validateDelivery(Map<String, Object> body) {
        if (blank(body.get("contacto_nombre"))) return "Ingresa el nombre de la persona que recibira el pedido";
        if (blank(body.get("contacto_telefono"))) return "Ingresa un numero de celular o telefono de contacto";
        if (!String.valueOf(body.get("contacto_telefono")).trim().matches("^[0-9+()\\s-]{6,20}$")) return "Ingresa un numero de contacto valido";
        if (blank(body.get("direccion_entrega"))) return "Ingresa la direccion de entrega";
        Object lat = body.get("direccion_entrega_lat");
        Object lng = body.get("direccion_entrega_lng");
        if ((lat == null) != (lng == null)) return "La ubicación debe incluir latitud y longitud";
        if (lat != null) {
            BigDecimal latitude = decimalOrNull(lat);
            BigDecimal longitude = decimalOrNull(lng);
            if (latitude == null || longitude == null
                    || latitude.compareTo(BigDecimal.valueOf(-90)) < 0 || latitude.compareTo(BigDecimal.valueOf(90)) > 0
                    || longitude.compareTo(BigDecimal.valueOf(-180)) < 0 || longitude.compareTo(BigDecimal.valueOf(180)) > 0) {
                return "La ubicación seleccionada no es válida";
            }
        }
        if (blank(body.get("distrito"))) return "Ingresa el distrito o ciudad de entrega";
        if (body.get("referencia") != null && String.valueOf(body.get("referencia")).length() > 300) return "La referencia no debe superar los 300 caracteres";
        return null;
    }

    private static boolean blank(Object value) {
        return value == null || String.valueOf(value).trim().isEmpty();
    }

    private static Object emptyToNull(Object value) {
        return value == null || String.valueOf(value).isBlank() ? null : value;
    }

    private static Integer integer(Object value) {
        return ((Number) value).intValue();
    }

    private static BigDecimal decimal(Object value) {
        return value instanceof BigDecimal bd ? bd : new BigDecimal(String.valueOf(value));
    }

    private static BigDecimal decimalOrNull(Object value) {
        if (value == null) return null;
        try { return new BigDecimal(value.toString()); }
        catch (NumberFormatException ex) { return null; }
    }

    private static String string(Object value) { return value == null ? null : value.toString(); }

    private Map<String, Object> shipmentUrls(Map<String, Object> source) {
        Map<String, Object> row = new java.util.HashMap<>(source);
        row.put("envase_envio_boleta_url", storage.publicUrl(string(row.get("envase_envio_boleta_key"))));
        row.put("envio_pedido_boleta_url", storage.publicUrl(string(row.get("envio_pedido_boleta_key"))));
        row.remove("envase_envio_boleta_key");
        row.remove("envio_pedido_boleta_key");
        return row;
    }
}
