class Pedido {
  const Pedido({
    required this.id,
    required this.numero,
    required this.total,
    required this.estado,
    this.fecha,
    this.nombreContacto,
    this.telefono,
    this.direccion,
    this.distrito,
    this.referencia,
    this.notas,
    this.tieneEnvaseCliente = false,
    this.cantidadEnvasesCliente = 0,
    this.envaseEnvioAgencia,
    this.envaseEnvioGuia,
    this.envaseEnvioCosto,
    this.envaseEnvioBoletaUrl,
    this.envaseRecibidoFecha,
    this.envaseDestino,
    this.envaseReceptor,
    this.envaseTelefono,
    this.envioPedidoAgencia,
    this.envioPedidoGuia,
    this.envioPedidoCosto,
    this.envioPedidoBoletaUrl,
  });
  final int id;
  final String numero;
  final double total;
  final String estado;
  final String? fecha;
  final String? nombreContacto;
  final String? telefono;
  final String? direccion;
  final String? distrito;
  final String? referencia;
  final String? notas;
  final bool tieneEnvaseCliente;
  final int cantidadEnvasesCliente;
  final String? envaseEnvioAgencia;
  final String? envaseEnvioGuia;
  final double? envaseEnvioCosto;
  final String? envaseEnvioBoletaUrl;
  final String? envaseRecibidoFecha;
  final String? envaseDestino;
  final String? envaseReceptor;
  final String? envaseTelefono;
  final String? envioPedidoAgencia;
  final String? envioPedidoGuia;
  final double? envioPedidoCosto;
  final String? envioPedidoBoletaUrl;

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    id: (json['id'] as num).toInt(),
    numero: json['numero_pedido']?.toString() ?? '',
    total: double.tryParse('${json['total']}') ?? 0,
    estado: json['estado']?.toString() ?? 'pendiente',
    fecha: json['fecha_pedido']?.toString(),
    nombreContacto: json['contacto_nombre']?.toString(),
    telefono: json['contacto_telefono']?.toString(),
    direccion: json['direccion_entrega']?.toString(),
    distrito: json['distrito']?.toString(),
    referencia: json['referencia']?.toString(),
    notas: json['notas']?.toString(),
    tieneEnvaseCliente: json['tiene_envase_cliente'] == true,
    cantidadEnvasesCliente:
        (json['cantidad_envases_cliente'] as num?)?.toInt() ?? 0,
    envaseEnvioAgencia: json['envase_envio_agencia']?.toString(),
    envaseEnvioGuia: json['envase_envio_guia']?.toString(),
    envaseEnvioCosto: double.tryParse('${json['envase_envio_costo']}'),
    envaseEnvioBoletaUrl: json['envase_envio_boleta_url']?.toString(),
    envaseRecibidoFecha: json['envase_recibido_fecha']?.toString(),
    envaseDestino: json['envase_destino']?.toString(),
    envaseReceptor: json['envase_receptor']?.toString(),
    envaseTelefono: json['envase_telefono']?.toString(),
    envioPedidoAgencia: json['envio_pedido_agencia']?.toString(),
    envioPedidoGuia: json['envio_pedido_guia']?.toString(),
    envioPedidoCosto: double.tryParse('${json['envio_pedido_costo']}'),
    envioPedidoBoletaUrl: json['envio_pedido_boleta_url']?.toString(),
  );
}

class LineaPedido {
  const LineaPedido({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.envaseNombre,
    this.costoEnvaseUnitario = 0,
  });
  final int id;
  final int productoId;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final String? envaseNombre;
  final double costoEnvaseUnitario;

  factory LineaPedido.fromJson(Map<String, dynamic> json) => LineaPedido(
    id: (json['id'] as num).toInt(),
    productoId: (json['producto_id'] as num).toInt(),
    nombre: json['nombre']?.toString() ?? '',
    cantidad: (json['cantidad'] as num).toInt(),
    precioUnitario: double.tryParse('${json['precio_unitario']}') ?? 0,
    subtotal: double.tryParse('${json['subtotal']}') ?? 0,
    envaseNombre: json['envase_nombre']?.toString(),
    costoEnvaseUnitario:
        double.tryParse('${json['costo_envase_unitario']}') ?? 0,
  );
}

class DetallePedido {
  const DetallePedido({required this.pedido, required this.lineas});
  final Pedido pedido;
  final List<LineaPedido> lineas;
}
