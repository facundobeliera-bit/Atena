import '../../services/remote/multiuser_session.dart';
import 'package:flutter/material.dart';
import '../../models/solicitudes/solicitud_alumno.dart';
import '../../services/trayectoria_educativa_service.dart';
import '../../services/cuenta_service.dart';
import '../alumnos/trayectoria_educativa_page.dart';

class InstitucionTrayectoriaPage extends StatefulWidget {
  final String institucionId, areaId;
  const InstitucionTrayectoriaPage({
    super.key,
    required this.institucionId,
    required this.areaId,
  });
  @override
  State<InstitucionTrayectoriaPage> createState() =>
      _InstitucionTrayectoriaPageState();
}

class _InstitucionTrayectoriaPageState
    extends State<InstitucionTrayectoriaPage> {
  late Future<List<SolicitudAlumno>> _future;
  final _names = <String, String>{};
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = _read();
  }

  Future<List<SolicitudAlumno>> _read() async {
    final list = await TrayectoriaEducativaService.instance.inscripciones(
      widget.institucionId,
      widget.areaId,
    );
    for (final s in list) {
      _names[s.id] = MultiuserSession.enabled
          ? s.perfilId!
          : (await CuentaService.getPerfilAlumnoById(
                  s.perfilId!,
                ))?.displayName ??
                '';
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Trayectoria del alumnado')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: FutureBuilder<List<SolicitudAlumno>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Elegí una inscripción confirmada de esta área. Cada registro conserva alumno, grupo y operador.',
                ),
                const SizedBox(height: 16),
                if (snapshot.hasError) ...[
                  Text('No se pudo abrir el alumnado: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: const Text('Reintentar'),
                  ),
                ] else if (snapshot.data!.isEmpty)
                  const Text(
                    'No hay inscripciones confirmadas con cuenta, perfil y área verificables. No se asignan registros históricos por documento automáticamente.',
                  )
                else
                  for (final s in snapshot.data!)
                    Card(
                      child: ListTile(
                        key: ValueKey('education-enrollment-${s.id}'),
                        title: Text(
                          MultiuserSession.enabled
                              ? 'Perfil ${s.perfilId}'
                              : 'Alumno ${s.alumnoDocumento}',
                        ),
                        subtitle: Text(
                          '${_names[s.id]}\n${s.actividadNombre} · ${s.aula} · ${s.turno}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TrayectoriaEducativaPage.institucion(
                                  institucionId: widget.institucionId,
                                  areaId: widget.areaId,
                                  solicitudId: s.id,
                                ),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
