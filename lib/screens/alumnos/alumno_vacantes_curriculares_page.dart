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
  State<AlumnoVacantesCurricularesPage> createState() => _AlumnoVacantesCurricularesPageState();
}

enum _Disponibilidad { todas, disponibles, completas }

enum _Orden { gradoTurnoVacantes, vacantesPrimero, horario }

class _AlumnoVacantesCurricularesPageState extends State<AlumnoVacantesCurricularesPage> {
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
  void initState() { super.initState(); _cargar(); }

  @override
  void dispose() { _gradoCtrl.dispose(); _horarioCtrl.dispose(); super.dispose(); }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final id = widget.institucionId.trim();
      if (id.isEmpty) throw StateError('La institución no tiene un identificador válido.');
      final grupos = await ih.cargarGruposCurricularesInstitucion(id);
      if (!mounted) return;
      setState(() { _grupos = List<GrupoCurricular>.from(grupos); _cargando = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _cargando = false; _error = e.toString().replaceFirst('Exception: ', ''); _grupos = const []; });
    }
  }

  String _turnoLabel(TurnoCurricular t) => switch (t) {
    TurnoCurricular.manana => 'Mañana',
    TurnoCurricular.tarde => 'Tarde',
    TurnoCurricular.noche => 'Noche',
  };

  int _turnoOrder(TurnoCurricular t) => switch (t) {
    TurnoCurricular.manana => 0,
    TurnoCurricular.tarde => 1,
    TurnoCurricular.noche => 2,
  };

  List<String> _partes(String raw) => raw.trim().split('•').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  String _grado(GrupoCurricular g) { final p = _partes(g.nombreCurso); return p.length > 1 ? p[1] : g.nombreCurso.trim(); }
  String _nivel(GrupoCurricular g) { final p = _partes(g.nombreCurso); return p.length > 1 ? p.first : ''; }
  String _horario(GrupoCurricular g) {
    final i = (g.horaInicio ?? '').trim(); final f = (g.horaFin ?? '').trim();
    if (i.isEmpty && f.isEmpty) return 'Horario no informado';
    return '${i.isEmpty ? '--:--' : i} - ${f.isEmpty ? '--:--' : f}';
  }

  bool _coincide(GrupoCurricular g) {
    final grado = _grado(g).toLowerCase();
    final nombre = g.nombreCurso.toLowerCase();
    final fg = _gradoCtrl.text.trim().toLowerCase();
    if (fg.isNotEmpty && !grado.contains(fg) && !nombre.contains(fg)) return false;
    if (_turno != null && g.turno != _turno) return false;
    if (_soloVacantes && !g.tieneCuposDisponibles) return false;
    if (_disponibilidad == _Disponibilidad.disponibles && !g.tieneCuposDisponibles) return false;
    if (_disponibilidad == _Disponibilidad.completas && g.tieneCuposDisponibles) return false;
    final fh = _horarioCtrl.text.trim().toLowerCase();
    if (fh.isNotEmpty && !_horario(g).toLowerCase().contains(fh)) return false;
    return true;
  }

  int _gradoCompare(String a, String b) {
    final ma = RegExp(r'^(\d+)').firstMatch(a.trim());
    final mb = RegExp(r'^(\d+)').firstMatch(b.trim());
    if (ma != null && mb != null) {
      final c = (int.tryParse(ma.group(1)!) ?? 0).compareTo(int.tryParse(mb.group(1)!) ?? 0);
      if (c != 0) return c;
    }
    return a.toLowerCase().compareTo(b.toLowerCase());
  }

  List<GrupoCurricular> get _filtrados {
    final list = _grupos.where(_coincide).toList();
    list.sort((a, b) {
      if (_orden == _Orden.vacantesPrimero) {
        final c = b.cuposDisponibles.compareTo(a.cuposDisponibles); if (c != 0) return c;
      }
      if (_orden == _Orden.horario) {
        final c = (a.horaInicio ?? '').compareTo(b.horaInicio ?? ''); if (c != 0) return c;
      }
      var c = _gradoCompare(_grado(a), _grado(b)); if (c != 0) return c;
      c = _turnoOrder(a.turno).compareTo(_turnoOrder(b.turno)); if (c != 0) return c;
      c = b.cuposDisponibles.compareTo(a.cuposDisponibles); if (c != 0) return c;
      return (a.horaInicio ?? '').compareTo(b.horaInicio ?? '');
    });
    return list;
  }

  void _limpiar() => setState(() {
    _gradoCtrl.clear(); _horarioCtrl.clear(); _turno = null;
    _disponibilidad = _Disponibilidad.todas; _orden = _Orden.gradoTurnoVacantes; _soloVacantes = false;
  });

  Future<void> _solicitar(GrupoCurricular g) async {
    if (!g.tieneCuposDisponibles) { _mensaje('Esta vacante no tiene cupos disponibles.'); return; }
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AlumnoSolicitarVacantePage(
      alumnoDocumento: widget.alumnoDocumento,
      institucionId: widget.institucionId.trim(),
      institucionNombre: widget.institucionNombre,
      actividadNombre: g.nombreCurso,
      esCurricular: true,
      grupoCurricularId: g.id,
      aula: g.nombreCurso,
      turno: '${_turnoLabel(g.turno)} • ${(g.horaInicio ?? '').trim()}-${(g.horaFin ?? '').trim()}',
      ownerAccountId: widget.ownerAccountId,
      perfilId: widget.perfilId,
    )));
    if (mounted && ok == true) await _cargar();
  }

  void _mensaje(String text) { if (!mounted) return; ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(text))); }

  Widget _filtros() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.tune), const SizedBox(width: 8), Expanded(child: Text('Filtrar vacantes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900))), TextButton(onPressed: _limpiar, child: const Text('Limpiar'))]),
        const SizedBox(height: 10),
        TextField(controller: _gradoCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Grado / sala / año', hintText: 'Ej.: 1°, 2°, sala de 5, 4° año', prefixIcon: Icon(Icons.school_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<TurnoCurricular>(initialValue: _turno, decoration: const InputDecoration(labelText: 'Turno', prefixIcon: Icon(Icons.wb_sunny_outlined), border: OutlineInputBorder()), items: [const DropdownMenuItem(value: null, child: Text('Todos los turnos')), ...TurnoCurricular.values.map((t) => DropdownMenuItem(value: t, child: Text(_turnoLabel(t)))], onChanged: (v) => setState(() => _turno = v)),
        const SizedBox(height: 10),
        TextField(controller: _horarioCtrl, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Horario', hintText: 'Ej.: 08:00, 13:30 o 17:00', prefixIcon: Icon(Icons.schedule_outlined), border: OutlineInputBorder())),
        const SizedBox(height: 10),
        DropdownButtonFormField<_Disponibilidad>(initialValue: _disponibilidad, decoration: const InputDecoration(labelText: 'Vacantes', prefixIcon: Icon(Icons.event_seat_outlined), border: OutlineInputBorder()), items: const [DropdownMenuItem(value: _Disponibilidad.todas, child: Text('Todas')), DropdownMenuItem(value: _Disponibilidad.disponibles, child: Text('Solo con vacantes')), DropdownMenuItem(value: _Disponibilidad.completas, child: Text('Sin vacantes'))], onChanged: (v) => setState(() => _disponibilidad = v ?? _Disponibilidad.todas)),
        CheckboxListTile(contentPadding: EdgeInsets.zero, value: _soloVacantes, title: const Text('Mostrar solamente vacantes disponibles'), onChanged: (v) => setState(() => _soloVacantes = v ?? false)),
        DropdownButtonFormField<_Orden>(initialValue: _orden, decoration: const InputDecoration(labelText: 'Ordenar resultados', prefixIcon: Icon(Icons.sort), border: OutlineInputBorder()), items: const [DropdownMenuItem(value: _Orden.gradoTurnoVacantes, child: Text('Grado → turno → vacantes')), DropdownMenuItem(value: _Orden.vacantesPrimero, child: Text('Más vacantes primero')), DropdownMenuItem(value: _Orden.horario, child: Text('Por horario'))], onChanged: (v) => setState(() => _orden = v ?? _Orden.gradoTurnoVacantes)),
      ]),
    ),
  );

  Widget _card(GrupoCurricular g) {
    final disponible = g.tieneCuposDisponibles;
    return Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [if (_nivel(g).isNotEmpty) Text(_nivel(g), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)), Text(_grado(g), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))]), Chip(label: Text(disponible ? '${g.cuposDisponibles} vacantes' : 'Sin vacantes'))]),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [Chip(label: Text(_turnoLabel(g.turno))), Chip(label: Text(_horario(g))), Chip(label: Text('${g.cuposOcupados}/${g.cuposTotales} ocupados'))]),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: disponible ? () => _solicitar(g) : null, icon: const Icon(Icons.how_to_reg_outlined), label: Text(disponible ? 'Solicitar esta vacante' : 'Vacante completa'))),
    ])));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vacantes curriculares'), actions: [IconButton(onPressed: _cargando ? null : _cargar, icon: const Icon(Icons.refresh))]),
    body: _cargando ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(_error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton.icon(onPressed: _cargar, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))])) : RefreshIndicator(onRefresh: _cargar, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [Text(widget.institucionNombre, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 4), const Text('Elegí la vacante según grado, turno, horario y disponibilidad.'), const SizedBox(height: 16), _filtros(), const SizedBox(height: 16), Text('${_filtrados.length} vacantes encontradas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 10), if (_filtrados.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No hay vacantes que coincidan con los filtros.', textAlign: TextAlign.center)) else for (final g in _filtrados) ...[_card(g), const SizedBox(height: 10)]])),
  );
}
