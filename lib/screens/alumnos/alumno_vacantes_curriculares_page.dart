import 'package:flutter/material.dart';

import '../../models/instituciones/grupo_curricular.dart';
import '../../services/instituciones_helpers.dart' as ih;
import 'alumno_solicitar_vacante_page.dart';

class AlumnoVacantesCurricularesPage extends StatefulWidget {
  final String institucionId;
  final String institucionNombre;
  final String alumnoDocumento;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoVacantesCurricularesPage({
    super.key,
    required this.institucionId,
    required this.institucionNombre,
    required this.alumnoDocumento,
    required this.ownerAccountId,
    required this.perfilId,
  });

  @override
  State<AlumnoVacantesCurricularesPage> createState() =>
      _AlumnoVacantesCurricularesPageState();
}

enum _Disponibilidad { todas, disponibles, completas }
enum _Orden { gradoTurnoVacantes, vacantesPrimero, horario }

class _AlumnoVacantesCurricularesPageState
    extends State<AlumnoVacantesCurricularesPage> {
  bool _cargando = true;
  String? _error;
  List<GrupoCurricular> _grupos = const [];

  final _gradoCtrl = TextEditingController();
  final _horarioCtrl = TextEditingController();

  TurnoCurricular? _turno;
  _Disponibilidad _disponibilidad = _Disponibilidad.todas;
  _Orden _orden = _Orden.gradoTurnoVacantes;
  bool _soloVacantes = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _gradoCtrl.dispose();
    _horarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (!mounted) return;

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final id = widget.institucionId.trim();
      if (id.isEmpty) {
        throw StateError('La institución no tiene un identificador válido.');
      }

      final grupos = await ih.cargarGruposCurricularesInstitucion(id);

      if (!mounted) return;
      setState(() {
        _grupos = List<GrupoCurricular>.from(grupos);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _grupos = const [];
      });
    }
  }

  String _turnoLabel(TurnoCurricular turno) {
    switch (turno) {
      case TurnoCurricular.manana:
        return 'Mañana';
      case TurnoCurricular.tarde:
        return 'Tarde';
      case TurnoCurricular.noche:
        return 'Noche';
    }
  }

  int _turnoOrder(TurnoCurricular turno) {
    switch (turno) {
      case TurnoCurricular.manana:
        return 0;
      case TurnoCurricular.tarde:
        return 1;
      case TurnoCurricular.noche:
        return 2;
    }
  }

  List<String> _partes(String raw) {
    return raw
        .trim()
        .split('•')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _grado(GrupoCurricular grupo) {
    final partes = _partes(grupo.nombreCurso);
    return partes.length > 1 ? partes[1] : grupo.nombreCurso.trim();
  }

  String _nivel(GrupoCurricular grupo) {
    final partes = _partes(grupo.nombreCurso);
    return partes.length > 1 ? partes.first : '';
  }

  String _horario(GrupoCurricular grupo) {
    final inicio = (grupo.horaInicio ?? '').trim();
    final fin = (grupo.horaFin ?? '').trim();

    if (inicio.isEmpty && fin.isEmpty) return 'Horario no informado';
    return '${inicio.isEmpty ? '--:--' : inicio} - ${fin.isEmpty ? '--:--' : fin}';
  }

  bool _coincide(GrupoCurricular grupo) {
    final grado = _grado(grupo).toLowerCase();
    final nombre = grupo.nombreCurso.toLowerCase();
    final filtroGrado = _gradoCtrl.text.trim().toLowerCase();

    if (filtroGrado.isNotEmpty &&
        !grado.contains(filtroGrado) &&
        !nombre.contains(filtroGrado)) {
      return false;
    }

    if (_turno != null && grupo.turno != _turno) return false;

    if (_soloVacantes && !grupo.tieneCuposDisponibles) return false;

    if (_disponibilidad == _Disponibilidad.disponibles &&
        !grupo.tieneCuposDisponibles) {
      return false;
    }

    if (_disponibilidad == _Disponibilidad.completas &&
        grupo.tieneCuposDisponibles) {
      return false;
    }

    final filtroHorario = _horarioCtrl.text.trim().toLowerCase();
    if (filtroHorario.isNotEmpty &&
        !_horario(grupo).toLowerCase().contains(filtroHorario)) {
      return false;
    }

    return true;
  }

  int _gradoCompare(String a, String b) {
    final matchA = RegExp(r'^(\d+)').firstMatch(a.trim());
    final matchB = RegExp(r'^(\d+)').firstMatch(b.trim());

    if (matchA != null && matchB != null) {
      final numeroA = int.tryParse(matchA.group(1)!) ?? 0;
      final numeroB = int.tryParse(matchB.group(1)!) ?? 0;
      final comparacion = numeroA.compareTo(numeroB);
      if (comparacion != 0) return comparacion;
    }

    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  List<GrupoCurricular> get _filtrados {
    final lista = _grupos.where(_coincide).toList();

    lista.sort((a, b) {
      if (_orden == _Orden.vacantesPrimero) {
        final comparacion =
            b.cuposDisponibles.compareTo(a.cuposDisponibles);
        if (comparacion != 0) return comparacion;
      }

      if (_orden == _Orden.horario) {
        final comparacion =
            (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
        if (comparacion != 0) return comparacion;
      }

      var comparacion = _gradoCompare(_grado(a), _grado(b));
      if (comparacion != 0) return comparacion;

      comparacion = _turnoOrder(a.turno).compareTo(_turnoOrder(b.turno));
      if (comparacion != 0) return comparacion;

      comparacion = b.cuposDisponibles.compareTo(a.cuposDisponibles);
      if (comparacion != 0) return comparacion;

      return (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
    });

    return lista;
  }

  void _limpiar() {
    setState(() {
      _gradoCtrl.clear();
      _horarioCtrl.clear();
      _turno = null;
      _disponibilidad = _Disponibilidad.todas;
      _orden = _Orden.gradoTurnoVacantes;
      _soloVacantes = false;
    });
  }

  Future<void> _solicitar(GrupoCurricular grupo) async {
    if (!grupo.tieneCuposDisponibles) {
      _mensaje('Esta vacante no tiene cupos disponibles.');
      return;
    }

    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AlumnoSolicitarVacantePage(
          alumnoDocumento: widget.alumnoDocumento,
          institucionId: widget.institucionId.trim(),
          institucionNombre: widget.institucionNombre,
          actividadNombre: grupo.nombreCurso,
          esCurricular: true,
          grupoCurricularId: grupo.id,
          aula: grupo.nombreCurso,
          turno:
              '${_turnoLabel(grupo.turno)} • ${(grupo.horaInicio ?? '').trim()}-${(grupo.horaFin ?? '').trim()}',
          ownerAccountId: widget.ownerAccountId,
          perfilId: widget.perfilId,
        ),
      ),
    );

    if (mounted && resultado == true) {
      await _cargar();
    }
  }

  void _mensaje(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Widget _filtros() {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtrar vacantes',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                TextButton(
                  onPressed: _limpiar,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _gradoCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Grado / sala / año',
                hintText: 'Ej.: 1°, 2°, sala de 5, 4° año',
                prefixIcon: Icon(Icons.school_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<TurnoCurricular?>(
              value: _turno,
              decoration: const InputDecoration(
                labelText: 'Turno',
                prefixIcon: Icon(Icons.wb_sunny_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<TurnoCurricular?>(
                  value: null,
                  child: Text('Todos los turnos'),
                ),
                ...TurnoCurricular.values.map(
                  (turno) => DropdownMenuItem<TurnoCurricular?>(
                    value: turno,
                    child: Text(_turnoLabel(turno)),
                  ),
                ),
              ],
              onChanged: (valor) => setState(() => _turno = valor),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _horarioCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Horario',
                hintText: 'Ej.: 08:00, 13:30 o 17:00',
                prefixIcon: Icon(Icons.schedule_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<_Disponibilidad>(
              value: _disponibilidad,
              decoration: const InputDecoration(
                labelText: 'Vacantes',
                prefixIcon: Icon(Icons.event_seat_outlined),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _Disponibilidad.todas,
                  child: Text('Todas'),
                ),
                DropdownMenuItem(
                  value: _Disponibilidad.disponibles,
                  child: Text('Solo con vacantes'),
                ),
                DropdownMenuItem(
                  value: _Disponibilidad.completas,
                  child: Text('Sin vacantes'),
                ),
              ],
              onChanged: (valor) => setState(
                () => _disponibilidad = valor ?? _Disponibilidad.todas,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _soloVacantes,
              title: const Text('Mostrar solamente vacantes disponibles'),
              onChanged: (valor) => setState(
                () => _soloVacantes = valor ?? false,
              ),
            ),
            DropdownButtonFormField<_Orden>(
              value: _orden,
              decoration: const InputDecoration(
                labelText: 'Ordenar resultados',
                prefixIcon: Icon(Icons.sort),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: _Orden.gradoTurnoVacantes,
                  child: Text('Grado → turno → vacantes'),
                ),
                DropdownMenuItem(
                  value: _Orden.vacantesPrimero,
                  child: Text('Más vacantes primero'),
                ),
                DropdownMenuItem(
                  value: _Orden.horario,
                  child: Text('Por horario'),
                ),
              ],
              onChanged: (valor) => setState(
                () => _orden = valor ?? _Orden.gradoTurnoVacantes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(GrupoCurricular grupo) {
    final disponible = grupo.tieneCuposDisponibles;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_nivel(grupo).isNotEmpty)
                        Text(
                          _nivel(grupo),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      Text(
                        _grado(grupo),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    disponible
                        ? '${grupo.cuposDisponibles} vacantes'
                        : 'Sin vacantes',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_turnoLabel(grupo.turno))),
                Chip(label: Text(_horario(grupo))),
                Chip(
                  label: Text(
                    '${grupo.cuposOcupados}/${grupo.cuposTotales} ocupados',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: disponible ? () => _solicitar(grupo) : null,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: Text(
                  disponible
                      ? 'Solicitar esta vacante'
                      : 'Vacante completa',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacantes curriculares'),
        actions: [
          IconButton(
            onPressed: _cargando ? null : _cargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _cargar,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      Text(
                        widget.institucionNombre,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Elegí la vacante según grado, turno, horario y disponibilidad.',
                      ),
                      const SizedBox(height: 16),
                      _filtros(),
                      const SizedBox(height: 16),
                      Text(
                        '${_filtrados.length} vacantes encontradas',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      if (_filtrados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No hay vacantes que coincidan con los filtros.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        for (final grupo in _filtrados) ...[
                          _card(grupo),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
                ),
    );
  }
}
