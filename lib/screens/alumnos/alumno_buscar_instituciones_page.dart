import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../models/extracurriculares/bloque_extracurricular.dart';
import '../../models/instituciones/instituciones_integrado.dart';
import '../../services/alumno_instituciones_search_service.dart';
import 'alumno_seleccion_grupo_extracurricular_page.dart';
import 'alumno_vacantes_curriculares_page.dart';

class AlumnoBuscarInstitucionesPage extends StatefulWidget {
  final String alumnoDni;
  final String ownerAccountId;
  final String perfilId;

  const AlumnoBuscarInstitucionesPage({super.key, required this.alumnoDni, required this.ownerAccountId, required this.perfilId});

  @override
  State<AlumnoBuscarInstitucionesPage> createState() => _AlumnoBuscarInstitucionesPageState();
}

class _AlumnoBuscarInstitucionesPageState extends State<AlumnoBuscarInstitucionesPage> {
  final _nombreCtrl = TextEditingController();
  final _ciudadCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();

  AlumnoBusquedaScope? _scope;
  String? _pais;
  String? _provincia;
  NivelCurricular? _nivel;
  TipoInstitucion? _tipoInstitucion;
  ModalidadCursado? _modalidad;
  final Set<BloqueExtracurricular> _bloques = {};
  bool _soloVacantes = false;
  AlumnoPrecioFiltro _precio = AlumnoPrecioFiltro.todos;
  bool _usarUbicacion = false;
  bool _cargandoUbicacion = false;
  double? _userLat;
  double? _userLng;
  double? _distanciaMaxima;
  bool _ordenarPorDistancia = false;
  bool _cargando = false;
  String? _error;
  List<AlumnoInstitucionSearchResult> _resultados = const [];

  static const List<String> _paises = ['Argentina','Bolivia','Brasil','Chile','Colombia','España','México','Paraguay','Perú','Uruguay'];
  static const List<String> _provinciasArgentina = ['Buenos Aires','Catamarca','Chaco','Chubut','Córdoba','Corrientes','Entre Ríos','Formosa','Jujuy','La Pampa','La Rioja','Mendoza','Misiones','Neuquén','Río Negro','Salta','San Juan','San Luis','Santa Cruz','Santa Fe','Santiago del Estero','Tierra del Fuego, Antártida e Islas del Atlántico Sur','Tucumán','Ciudad Autónoma de Buenos Aires'];

  @override
  void initState() {
    super.initState();
    _nombreCtrl.addListener(_onFieldChanged); _ciudadCtrl.addListener(_onFieldChanged); _regionCtrl.addListener(_onFieldChanged); _edadCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _ciudadCtrl.dispose(); _regionCtrl.dispose(); _edadCtrl.dispose(); super.dispose(); }

  void _onFieldChanged() { if (_scope == null || _cargando) return; setState(() {}); }

  void _seleccionarScope(AlumnoBusquedaScope scope) {
    setState(() { _scope = scope; _nivel = null; _tipoInstitucion = null; _modalidad = null; _bloques.clear(); _soloVacantes = false; _precio = AlumnoPrecioFiltro.todos; _error = null; _resultados = const []; });
  }

  Future<void> _usarMiUbicacion() async {
    setState(() { _cargandoUbicacion = true; _error = null; });
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw StateError('La ubicación del dispositivo está desactivada.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw StateError('No se concedió permiso para acceder a la ubicación.');
      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() { _usarUbicacion = true; _userLat = position.latitude; _userLng = position.longitude; _cargandoUbicacion = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _cargandoUbicacion = false; _usarUbicacion = false; _userLat = null; _userLng = null; _error = e.toString().replaceFirst('Bad state: ', ''); });
    }
  }

  void _quitarUbicacion() { setState(() { _usarUbicacion = false; _userLat = null; _userLng = null; _distanciaMaxima = null; _ordenarPorDistancia = false; }); }

  Future<void> _abrirFiltroBloques() async {
    final tmp = Set<BloqueExtracurricular>.from(_bloques);
    final result = await showModalBottomSheet<Set<BloqueExtracurricular>>(context: context, isScrollControlled: true, builder: (ctx) => SafeArea(child: StatefulBuilder(builder: (ctx, setSheetState) => Padding(padding: const EdgeInsets.fromLTRB(16,16,16,20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [const Expanded(child: Text('Módulo extracurricular', style: TextStyle(fontWeight: FontWeight.w800))), TextButton(onPressed: () => setSheetState(tmp.clear), child: const Text('Limpiar'))]),
      const SizedBox(height: 8),
      for (final bloque in BloqueExtracurricularX.ordered()) CheckboxListTile(value: tmp.contains(bloque), title: Text(bloque.label), subtitle: Text(bloque.descripcionCorta), onChanged: (value) { setSheetState(() { if (value == true) { tmp.add(bloque); } else { tmp.remove(bloque); } }); }),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, tmp), child: const Text('Aplicar módulos'))),
    ]))));
    if (!mounted || result == null) return;
    setState(() { _bloques..clear()..addAll(result); });
  }

  Future<void> _buscar() async {
    final scope = _scope; if (scope == null) return;
    setState(() { _cargando = true; _error = null; });
    try {
      final edad = int.tryParse(_edadCtrl.text.trim()); final region = _regionCtrl.text.trim();
      final results = await AlumnoInstitucionesSearchService.search(AlumnoInstitucionSearchFilters(scope: scope, texto: _nombreCtrl.text.trim(), pais: _pais, provincia: _provincia ?? (region.isEmpty ? null : region), ciudad: _ciudadCtrl.text.trim().isEmpty ? null : _ciudadCtrl.text.trim(), nivel: _nivel, tipoInstitucion: _tipoInstitucion, modalidadCursado: _modalidad, bloques: Set<BloqueExtracurricular>.from(_bloques), edad: edad, soloConVacantes: _soloVacantes, precio: _precio, userLat: _usarUbicacion ? _userLat : null, userLng: _usarUbicacion ? _userLng : null, maxDistanceKm: _usarUbicacion ? _distanciaMaxima : null, ordenarPorDistancia: _usarUbicacion && _ordenarPorDistancia));
      if (!mounted) return; setState(() { _resultados = results; _cargando = false; });
    } catch (e) { if (!mounted) return; setState(() { _cargando = false; _error = e.toString().replaceFirst('Exception: ', ''); _resultados = const []; }); }
  }

  String _scopeDescription(AlumnoBusquedaScope scope) => scope == AlumnoBusquedaScope.curricular ? 'Propuestas educativas que forman parte de la trayectoria escolar y curricular, organizadas según nivel y ciclo educativo.' : 'Actividades, propuestas y espacios de formación que no forman parte de la trayectoria curricular escolar, como deportes y entrenamiento, talleres, idiomas, arte, música, cursos independientes y otras propuestas formativas.';
  String _levelLabel(NivelCurricular value) => switch (value) { NivelCurricular.jardin => 'Jardín', NivelCurricular.primaria => 'Primaria', NivelCurricular.secundaria => 'Secundaria', NivelCurricular.tecnica => 'Técnica', NivelCurricular.terciario => 'Terciario' };
  String _tipoLabel(TipoInstitucion value) => switch (value) { TipoInstitucion.jardin => 'Jardín', TipoInstitucion.primaria => 'Primaria', TipoInstitucion.secundaria => 'Secundaria', TipoInstitucion.tecnica => 'Técnica', TipoInstitucion.terciario => 'Terciario', TipoInstitucion.taller => 'Taller', TipoInstitucion.club => 'Club', TipoInstitucion.otra => 'Otra' };
  String _modalidadLabel(ModalidadCursado value) => switch (value) { ModalidadCursado.presencial => 'Presencial', ModalidadCursado.remoto => 'Remoto', ModalidadCursado.hibrido => 'Híbrido' };
  String _distanciaLabel() => _distanciaMaxima == null ? 'Sin límite de distancia' : 'Hasta ${_distanciaMaxima!.toStringAsFixed(0)} km';

  Future<void> _mostrarFiltrosUbicacion() async {
    final selected = await showModalBottomSheet<double?>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [const ListTile(title: Text('Distancia máxima'), subtitle: Text('Solo funciona cuando las instituciones tienen coordenadas geográficas registradas.')), for (final km in <double>[1,3,5,10,20,50]) RadioListTile<double>(value: km, groupValue: _distanciaMaxima, title: Text('Hasta ${km.toStringAsFixed(0)} km'), onChanged: (value) => Navigator.pop(ctx, value)), RadioListTile<double?>(value: null, groupValue: _distanciaMaxima, title: const Text('Sin límite'), onChanged: (_) => Navigator.pop(ctx, null))])));
    if (!mounted) return; setState(() => _distanciaMaxima = selected);
  }

  Widget _scopeCard({required AlumnoBusquedaScope scope, required IconData icon}) {
    final selected = _scope == scope; final cs = Theme.of(context).colorScheme;
    return Card(elevation: 0, color: selected ? cs.primaryContainer : cs.surfaceContainerHighest, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 1.5 : 1)), child: InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _seleccionarScope(scope), child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 30), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(scope == AlumnoBusquedaScope.curricular ? 'Curricular' : 'Extracurricular', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), const SizedBox(height: 6), Text(_scopeDescription(scope))])), Radio<AlumnoBusquedaScope>(value: scope, groupValue: _scope, onChanged: (_) => _seleccionarScope(scope))]))));
  }

  Widget _sectionTitle(String title, {String? subtitle}) => Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)), if (subtitle != null) ...[const SizedBox(height: 3), Text(subtitle)]]));

  Widget _buildFilters() {
    final scope = _scope; if (scope == null) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    InputDecoration inputDecoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)));
    return Column(children: [
      _sectionTitle('Datos de la institución'),
      TextField(controller: _nombreCtrl, decoration: inputDecoration('Nombre de la institución', Icons.search)), const SizedBox(height: 10),
      _sectionTitle('Ubicación', subtitle: 'Podés buscar cerca de vos o elegir un país, provincia y localidad diferentes.'),
      DropdownButtonFormField<String>(initialValue: _pais, isExpanded: true, decoration: inputDecoration('País', Icons.public), items: [const DropdownMenuItem<String>(value: null, child: Text('Todos los países')), ..._paises.map((p) => DropdownMenuItem<String>(value: p, child: Text(p)))], onChanged: (v) => setState(() { _pais = v; _provincia = null; _regionCtrl.clear(); })), const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [OutlinedButton.icon(onPressed: _cargandoUbicacion ? null : _usarMiUbicacion, icon: _cargandoUbicacion ? const SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.my_location), label: Text(_usarUbicacion ? 'Ubicación actual activada' : 'Usar mi ubicación')), if (_usarUbicacion) OutlinedButton.icon(onPressed: _quitarUbicacion, icon: const Icon(Icons.close), label: const Text('Quitar ubicación'))]),
      if (_usarUbicacion) ...[const SizedBox(height:8), Row(children: [Expanded(child: OutlinedButton.icon(onPressed:_mostrarFiltrosUbicacion, icon:const Icon(Icons.social_distance), label:Text(_distanciaLabel()))), const SizedBox(width:8), Expanded(child:SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,value:_ordenarPorDistancia,title:const Text('Más cercanas primero'),onChanged:(v)=>setState(()=>_ordenarPorDistancia=v)))])],
      const SizedBox(height: 10),
      if (_pais == null || _pais == 'Argentina') DropdownButtonFormField<String>(initialValue:_provincia,isExpanded:true,decoration:inputDecoration('Provincia',Icons.map_outlined),items:[const DropdownMenuItem<String>(value:null,child:Text('Todas las provincias')),..._provinciasArgentina.map((p)=>DropdownMenuItem<String>(value:p,child:Text(p)))],onChanged:(v)=>setState(()=>_provincia=v)) else TextField(controller:_regionCtrl,decoration:inputDecoration('Provincia, estado o región',Icons.map_outlined)), const SizedBox(height:10),
      TextField(controller:_ciudadCtrl,decoration:inputDecoration('Localidad o ciudad',Icons.location_city)),
      _sectionTitle('Filtros específicos'),
      if (scope == AlumnoBusquedaScope.curricular) ...[DropdownButtonFormField<NivelCurricular>(initialValue:_nivel,isExpanded:true,decoration:inputDecoration('Nivel curricular',Icons.school_outlined),items:[const DropdownMenuItem<NivelCurricular>(value:null,child:Text('Todos los niveles')),...NivelCurricular.values.map((e)=>DropdownMenuItem(value:e,child:Text(_levelLabel(e)))],onChanged:(v)=>setState(()=>_nivel=v)),const SizedBox(height:10),const InputDecorator(decoration:InputDecoration(labelText:'Ciclo curricular',border:OutlineInputBorder()),child:Text('El ciclo curricular todavía no está almacenado como dato canónico independiente en el perfil institucional.'))] else ...[InkWell(onTap:_abrirFiltroBloques,borderRadius:BorderRadius.circular(12),child:InputDecorator(decoration:inputDecoration('Módulo extracurricular',Icons.category_outlined),child:Text(_bloques.isEmpty?'Todos los módulos':_bloques.map((e)=>e.label).join(' • '),maxLines:2,overflow:TextOverflow.ellipsis))),const SizedBox(height:10),TextField(controller:_edadCtrl,keyboardType:TextInputType.number,decoration:inputDecoration('Edad',Icons.cake_outlined).copyWith(hintText:'Ejemplo: 12')),const SizedBox(height:10),DropdownButtonFormField<AlumnoPrecioFiltro>(initialValue:_precio,decoration:inputDecoration('Valor',Icons.payments_outlined),items:AlumnoPrecioFiltro.values.map((e)=>DropdownMenuItem(value:e,child:Text(e == AlumnoPrecioFiltro.todos?'Todos los valores':e == AlumnoPrecioFiltro.gratuitos?'Gratuitos':'Con costo'))).toList(),onChanged:(v)=>setState(()=>_precio=v??AlumnoPrecioFiltro.todos))],
      const SizedBox(height:10),
      DropdownButtonFormField<TipoInstitucion>(initialValue:_tipoInstitucion,isExpanded:true,decoration:inputDecoration('Tipo de institución',Icons.account_balance_outlined),items:[const DropdownMenuItem<TipoInstitucion>(value:null,child:Text('Todos los tipos')),...TipoInstitucion.values.map((e)=>DropdownMenuItem(value:e,child:Text(_tipoLabel(e)))],onChanged:(v)=>setState(()=>_tipoInstitucion=v)), const SizedBox(height:10),
      DropdownButtonFormField<ModalidadCursado>(initialValue:_modalidad,decoration:inputDecoration('Modalidad de cursado',Icons.devices_outlined),items:[const DropdownMenuItem<ModalidadCursado>(value:null,child:Text('Todas las modalidades')),...ModalidadCursado.values.map((e)=>DropdownMenuItem(value:e,child:Text(_modalidadLabel(e)))],onChanged:(v)=>setState(()=>_modalidad=v)),
      const SizedBox(height:6), CheckboxListTile(contentPadding:EdgeInsets.zero,value:_soloVacantes,title:const Text('Mostrar solamente propuestas con vacantes disponibles'),onChanged:(v)=>setState(()=>_soloVacantes=v??false)), const SizedBox(height:8),
      SizedBox(width:double.infinity,child:FilledButton.icon(onPressed:_cargando?null:_buscar,icon:const Icon(Icons.search),label:Text(_cargando?'Buscando...':'Buscar instituciones'))), const SizedBox(height:8), Text('Los filtros se aplican sobre los datos actualmente registrados en los perfiles de Atena.',style:Theme.of(context).textTheme.bodySmall?.copyWith(color:cs.onSurfaceVariant)),
    ]);
  }

  Widget _buildResultCard(AlumnoInstitucionSearchResult result) {
    final inst = result.institucion; final cs = Theme.of(context).colorScheme; final extra = inst.actividadesExtracurriculares.where((a)=>a.activa).toList(); final bloques = extra.map((a)=>a.bloque).toSet().toList(); final niveles = inst.planConfig?.niveles.where((e)=>e.habilitado).map((e)=>_levelLabel(e.nivel)).toList() ?? const <String>[];
    final location = [if(inst.ciudad.trim().isNotEmpty)inst.ciudad.trim(),if(inst.provincia.trim().isNotEmpty)inst.provincia.trim()].join(', ');
    return Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:cs.outlineVariant)),child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(inst.nombre,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900))),IconButton(tooltip:'Ver perfil',onPressed:()=>_mostrarInstitucion(inst),icon:const Icon(Icons.account_balance_outlined))]),if(location.isNotEmpty)Padding(padding:const EdgeInsets.only(top:3),child:Text(location)),if(result.distanciaKm!=null)Padding(padding:const EdgeInsets.only(top:3),child:Text('${result.distanciaKm!.toStringAsFixed(1)} km de distancia')),const SizedBox(height:10),Wrap(spacing:6,runSpacing:6,children:[if(inst.curricular)const Chip(label:Text('Curricular')),if(inst.extracurricular)const Chip(label:Text('Extracurricular')),Chip(label:Text(_tipoLabel(inst.tipoInstitucion))),Chip(label:Text(_modalidadLabel(inst.modalidad)))]),if(niveles.isNotEmpty)...[const SizedBox(height:8),Text('Niveles: ${niveles.join(' • ')}')],if(bloques.isNotEmpty)...[const SizedBox(height:8),Text('Módulos: ${bloques.map((e)=>e.label).join(' • ')}')],const SizedBox(height:12),Row(children:[Expanded(child:FilledButton.icon(onPressed:()=>_mostrarInstitucion(inst),icon:const Icon(Icons.account_balance_outlined),label:const Text('Ver perfil'))),const SizedBox(width:8),Expanded(child:FilledButton.icon(onPressed:()=>_solicitarVacante(inst),icon:const Icon(Icons.how_to_reg_outlined),label:const Text('Solicitar vacante')))])])));
  }

  Future<void> _solicitarVacante(Institucion inst) async {
    if (!inst.curricular && !inst.extracurricular) return;
    if (inst.curricular && inst.extracurricular) {
      final choice = await showModalBottomSheet<AlumnoBusquedaScope>(context:context,showDragHandle:true,builder:(ctx)=>SafeArea(child:Padding(padding:const EdgeInsets.fromLTRB(18,8,18,24),child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text('Solicitar vacante',style:Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Elegí qué tipo de propuesta querés explorar.'),const SizedBox(height:14),FilledButton.icon(onPressed:()=>Navigator.pop(ctx,AlumnoBusquedaScope.curricular),icon:const Icon(Icons.school_outlined),label:const Text('Curricular')),const SizedBox(height:8),FilledButton.icon(onPressed:()=>Navigator.pop(ctx,AlumnoBusquedaScope.extracurricular),icon:const Icon(Icons.category_outlined),label:const Text('Extracurricular'))]))));
      if(!mounted||choice==null)return;
      if(choice==AlumnoBusquedaScope.curricular){await _abrirCurricular(inst);}else{await _abrirExtracurricular(inst);} return;
    }
    if(inst.curricular){await _abrirCurricular(inst);}else{await _abrirExtracurricular(inst);}
  }

  Future<void> _abrirCurricular(Institucion inst) async {
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>AlumnoVacantesCurricularesPage(institucionId:inst.id,institucionNombre:inst.nombre,alumnoDocumento:widget.alumnoDni,ownerAccountId:widget.ownerAccountId,perfilId:widget.perfilId)));
  }

  Future<void> _abrirExtracurricular(Institucion inst) async {
    final bloqueInicial = _bloques.length == 1 ? _bloques.first : null;
    await Navigator.push(context,MaterialPageRoute(builder:(_)=>AlumnoSeleccionGrupoExtracurricularPage(institucionId:inst.id,institucionNombre:inst.nombre,alumnoDocumento:widget.alumnoDni,ownerAccountId:widget.ownerAccountId,perfilId:widget.perfilId,bloqueInicial:bloqueInicial,filtroInicial:_nombreCtrl.text.trim())));
  }

  void _mostrarInstitucion(Institucion inst) {
    final extra = inst.actividadesExtracurriculares.where((a)=>a.activa).toList();
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,builder:(ctx)=>SafeArea(child:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(18,8,18,24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(inst.nombre,style:Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900))),const Chip(label:Text('Perfil institucional'))]),const SizedBox(height:10),if(inst.direccion.trim().isNotEmpty)Text('Dirección: ${inst.direccion.trim()}'),if(inst.pais.trim().isNotEmpty)Text('País: ${inst.pais.trim()}'),if(inst.ciudad.trim().isNotEmpty)Text('Localidad: ${inst.ciudad.trim()}'),if(inst.provincia.trim().isNotEmpty)Text('Provincia: ${inst.provincia.trim()}'),Text('Modalidad: ${_modalidadLabel(inst.modalidad)}'),const SizedBox(height:14),if(inst.curricular||inst.extracurricular)...[const Text('Propuestas disponibles',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:6),Wrap(spacing:6,runSpacing:6,children:[if(inst.curricular)const Chip(label:Text('Curricular')),if(inst.extracurricular)const Chip(label:Text('Extracurricular'))])],if(extra.isNotEmpty)...[const SizedBox(height:14),const Text('Propuestas extracurriculares',style:TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:6),for(final a in extra)ListTile(contentPadding:EdgeInsets.zero,title:Text(a.nombre),subtitle:Text([a.bloque.label,if((a.edades??'').trim().isNotEmpty)'Edades: ${a.edades}',if((a.precio??'').trim().isNotEmpty)'Valor: ${a.precio}'].join(' • ')))],const SizedBox(height:14),if(inst.curricular||inst.extracurricular)Row(children:[Expanded(child:FilledButton.icon(onPressed:(){Navigator.pop(ctx);_solicitarVacante(inst);},icon:const Icon(Icons.how_to_reg_outlined),label:const Text('Solicitar vacante')))])]))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(appBar:AppBar(title:Text(l10n.alumnoBuscarInstitucionesTitle)),body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,16,16,28),children:[Text('¿Qué estás buscando?',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Elegí primero el tipo de propuesta. Después podrás aplicar los filtros específicos correspondientes.'),const SizedBox(height:14),_scopeCard(scope:AlumnoBusquedaScope.curricular,icon:Icons.school_outlined),_scopeCard(scope:AlumnoBusquedaScope.extracurricular,icon:Icons.category_outlined),if(_scope!=null)...[const Divider(height:28),_buildFilters(),if(_error!=null)...[const SizedBox(height:16),Text(_error!,style:TextStyle(color:Theme.of(context).colorScheme.error,fontWeight:FontWeight.w700))],const SizedBox(height:20),if(_cargando)const Center(child:CircularProgressIndicator())else if(_resultados.isEmpty)Center(child:Padding(padding:const EdgeInsets.symmetric(vertical:24),child:Text('No se encontraron instituciones con los criterios seleccionados.',textAlign:TextAlign.center)))else...[Text('Instituciones encontradas: ${_resultados.length}',style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:10),for(final result in _resultados)...[_buildResultCard(result),const SizedBox(height:10)]]]))));
  }
}
