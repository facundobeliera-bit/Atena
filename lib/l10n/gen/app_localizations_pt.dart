// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'ATENA';

  @override
  String get alumnos => 'Alunos';

  @override
  String get instituciones => 'Instituições';

  @override
  String get institution => 'Instituição';

  @override
  String get perfiles => 'Perfis';

  @override
  String get crearPerfil => 'Criar perfil';

  @override
  String get crearPerfilTitulo => 'Criar um novo perfil';

  @override
  String get tipoAlumno => 'Aluno';

  @override
  String get tipoInstitucion => 'Instituição';

  @override
  String get actualizar => 'Atualizar';

  @override
  String get refresh => 'Atualizar';

  @override
  String get update => 'Atualizar';

  @override
  String get guardar => 'Salvar';

  @override
  String get save => 'Salvar';

  @override
  String get editar => 'Editar';

  @override
  String get edit => 'Editar';

  @override
  String get eliminar => 'Excluir';

  @override
  String get delete => 'Excluir';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get continuar => 'Continuar';

  @override
  String get continuarUltimoPerfil => 'Continuar com o último perfil';

  @override
  String get accept => 'Aceitar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reject => 'Rejeitar';

  @override
  String get apply => 'Aplicar';

  @override
  String get clear => 'Limpar';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get back => 'Voltar';

  @override
  String get open => 'Abrir';

  @override
  String get cuentaLabel => 'Conta';

  @override
  String accountLabel(Object ownerId) {
    return 'Conta: $ownerId';
  }

  @override
  String get signIn => 'Entrar';

  @override
  String get signOut => 'Sair';

  @override
  String get signInOrRegister => 'Entrar ou registrar';

  @override
  String get accessInstitutionAccount => 'Acessar conta da instituição';

  @override
  String get signInToEnableInstitutionFeatures =>
      'Entre para habilitar recursos da instituição';

  @override
  String get errorGenerico => 'Erro.';

  @override
  String get invalidSessionForThisAccount => 'Sessão inválida para esta conta.';

  @override
  String get cannotLoadInstitutionTryAgain =>
      'Não foi possível carregar a instituição. Tente novamente.';

  @override
  String get noPerfilesTodavia => 'Ainda não há perfis.\nCrie um para começar.';

  @override
  String get noPerfilesAlumnoTodavia => 'Ainda não há perfis de aluno.';

  @override
  String get accionAlumnoSinPerfil =>
      'Uma ação para Alunos foi recebida, mas esta conta não tem perfis de Aluno.';

  @override
  String get opcionNoDisponibleBuild =>
      'Esta opção ainda não está disponível nesta versão.';

  @override
  String get ingresarCrearCuenta => 'Entrar / Criar conta';

  @override
  String get accesoAlumnos => 'Acesso de alunos';

  @override
  String get ingresaCuentaEligePerfil =>
      'Entre com sua conta e escolha o perfil.';

  @override
  String get saving => 'Salvando...';

  @override
  String get registering => 'Registrando…';

  @override
  String get newLabel => 'Novo';

  @override
  String get modoOscuro => 'Modo escuro';

  @override
  String get idioma => 'Idioma';

  @override
  String get sistema => 'Sistema';

  @override
  String get espanol => 'Espanhol';

  @override
  String get ingles => 'Inglês';

  @override
  String get portugues => 'Português';

  @override
  String get landingTitle => 'ATENA';

  @override
  String get landingIngresar => 'Entrar';

  @override
  String get landingStudents => 'Alunos';

  @override
  String get landingInstitutions => 'Instituições';

  @override
  String get landingHeadingStudents => 'alunos';

  @override
  String get landingHeadingInstitutions => 'instituições';

  @override
  String get landingThemeSystem => 'Tema: Sistema';

  @override
  String get landingThemeLight => 'Tema: Claro';

  @override
  String get landingThemeDark => 'Tema: Escuro';

  @override
  String get landingLanguageTooltip => 'Idioma';

  @override
  String get landingLanguageSystem => 'Sistema';

  @override
  String get landingLanguageEs => 'Espanhol';

  @override
  String get landingLanguageEn => 'Inglês';

  @override
  String get landingLanguagePt => 'Português';

  @override
  String landingMissingAsset(Object path) {
    return 'ARQUIVO AUSENTE:\n$path';
  }

  @override
  String get vacancyManagement => 'Vagas';

  @override
  String vacancyManagementTitle(Object institucion) {
    return 'Gestão de vagas – $institucion';
  }

  @override
  String get recalculateOccupiedTooltip => 'Recalcular ocupadas (confirmadas)';

  @override
  String get summaryLabel => 'Resumo';

  @override
  String totalCapacityValue(Object valor) {
    return 'Capacidade total: $valor';
  }

  @override
  String occupiedValue(Object valor) {
    return 'Ocupadas: $valor';
  }

  @override
  String availableEstimatedValue(Object valor) {
    return 'Disponíveis (estimado): $valor';
  }

  @override
  String get noGroupsLoaded => 'Nenhum grupo/vaga carregado.';

  @override
  String vacancyGroupSubtitle(
    Object actividad,
    Object total,
    Object ocupados,
    Object disponibles,
  ) {
    return '$actividad · Capacidade $total · Ocupadas $ocupados · Disp $disponibles';
  }

  @override
  String get newGroupTitle => 'Novo grupo/vaga';

  @override
  String get editGroupTitle => 'Editar grupo/vaga';

  @override
  String get available => 'Disponível';

  @override
  String get availableShort => 'Disp';

  @override
  String get availableLabel => 'Disponíveis';

  @override
  String get fullLabel => 'Lotado';

  @override
  String get curricular => 'Curricular';

  @override
  String get curricularLabel => 'Curricular';

  @override
  String get curricularPlural => 'Curricular';

  @override
  String get extracurricular => 'Extracurricular';

  @override
  String get extracurricularLabel => 'Extracurricular';

  @override
  String get extracurricularPlural => 'Extracurricular';

  @override
  String get basic => 'Básico';

  @override
  String get standard => 'Padrão';

  @override
  String get premium => 'Premium';

  @override
  String get summary => 'Resumo';

  @override
  String get plan => 'Plano';

  @override
  String get code => 'Código';

  @override
  String get invalidInstitutionId => 'ID de instituição inválido.';

  @override
  String get institucionInvalidGeneric => 'Instituição inválida.';

  @override
  String get institutionGeneric => 'Instituição';

  @override
  String get institutionNotLoadedYet =>
      'A instituição ainda não foi carregada.';

  @override
  String get noActiveSessionGoBackToLogin =>
      'Sem sessão ativa. Volte ao login.';

  @override
  String get institutionsTitle => 'Instituições';

  @override
  String get backToHome => 'Voltar ao início';

  @override
  String get institutionAccess => 'Acesso da instituição';

  @override
  String institutionProfileIdLabel(Object perfilId) {
    return 'ID do perfil: $perfilId';
  }

  @override
  String get planPlaceholder => 'Gestão de plano';

  @override
  String get profilePlaceholder => 'Perfil da instituição';

  @override
  String get planUpper => 'PLANO';

  @override
  String get profileUpper => 'PERFIL';

  @override
  String get administrationUpper => 'ADMINISTRAÇÃO';

  @override
  String get planCardSubtitle => 'Gerenciar plano e módulos';

  @override
  String get profileCardSubtitle => 'Detalhes e apresentação da instituição';

  @override
  String get administrationCardSubtitle => 'Operação da instituição';

  @override
  String planAndStatusLine(Object plan, Object estado) {
    return 'Plano: $plan · Status: $estado';
  }

  @override
  String get workProfilesUpToPremium => 'Até 10 perfis de trabalho';

  @override
  String get workProfilesUpToStandard => 'Até 3 perfis de trabalho';

  @override
  String get moduleLabelGeneric => 'Módulo';

  @override
  String invalidModuleKeyShowingAll(Object key) {
    return 'Filtro inválido ($key). Mostrando todos os módulos.';
  }

  @override
  String loadErrorWithDetails(Object error) {
    return 'Erro ao carregar: $error';
  }

  @override
  String get confirmRequestTitle => 'Confirmar solicitação';

  @override
  String get rejectRequestTitle => 'Rejeitar solicitação';

  @override
  String get updateRequestTitle => 'Atualizar solicitação';

  @override
  String get confirmRequestBody => 'Deseja confirmar esta solicitação?';

  @override
  String get rejectRequestBody => 'Deseja rejeitar esta solicitação?';

  @override
  String get updateRequestBody => 'Deseja atualizar esta solicitação?';

  @override
  String activityWithName(Object nombre) {
    return 'Atividade: $nombre';
  }

  @override
  String activityWithValue(Object value) {
    return 'Atividade: $value';
  }

  @override
  String get rejectionReasonOptionalLabel => 'Motivo (opcional)';

  @override
  String get noteToStudentOptionalLabel => 'Nota para o aluno (opcional)';

  @override
  String get requestStatusPending => 'Pendente';

  @override
  String get requestStatusConfirmed => 'Confirmada';

  @override
  String get requestStatusRejected => 'Rejeitada';

  @override
  String get requestStatusCancelledByStudent => 'Cancelada pelo aluno';

  @override
  String get requestStatusCancelledByInstitution =>
      'Cancelada pela instituição';

  @override
  String get requestConfirmed => 'Solicitação confirmada.';

  @override
  String get requestRejected => 'Solicitação rejeitada.';

  @override
  String get requestUpdated => 'Solicitação atualizada.';

  @override
  String get requestIsNoLongerPending =>
      'Esta solicitação não está mais pendente.';

  @override
  String get noRequestsInSection => 'Não há solicitações nesta seção.';

  @override
  String get noPendingRequests => 'Não há solicitações pendentes.';

  @override
  String actionErrorWithDetails(Object error) {
    return 'Não foi possível concluir a ação: $error';
  }

  @override
  String get cannotOpenDocumentsMissingOwnerOrProfile =>
      'Não é possível abrir Documentação sem uma sessão válida.';

  @override
  String requestsTitleWithInstitution(Object institucion, Object subtitle) {
    return 'Solicitações – $institucion · $subtitle';
  }

  @override
  String pendingWithCount(Object count) {
    return 'Pendentes ($count)';
  }

  @override
  String confirmedWithCount(Object count) {
    return 'Confirmadas ($count)';
  }

  @override
  String rejectedWithCount(Object count) {
    return 'Rejeitadas ($count)';
  }

  @override
  String cancelledWithCount(Object count) {
    return 'Canceladas ($count)';
  }

  @override
  String invalidModuleFilterBanner(Object key) {
    return 'Filtro de módulo inválido ($key)';
  }

  @override
  String filteringByModuleBanner(Object module, Object key) {
    return 'Filtrando por módulo: $module ($key)';
  }

  @override
  String studentDocumentLine(Object doc) {
    return 'Documento: $doc';
  }

  @override
  String typeLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String moduleLine(Object module) {
    return 'Módulo: $module';
  }

  @override
  String groupOrClassLine(Object valor) {
    return 'Turma/Grupo: $valor';
  }

  @override
  String shiftLine(Object valor) {
    return 'Turno: $valor';
  }

  @override
  String statusLine(Object estado) {
    return 'Status: $estado';
  }

  @override
  String get requestOrViewDocumentsCta => 'Solicitar ou ver documentação';

  @override
  String get documentsMissingOwnerOrProfileDisabledCta =>
      'Documentação indisponível';

  @override
  String get notificationsTitle => 'Notificações';

  @override
  String notificationsTitleWithNewCount(Object count) {
    return 'Notificações ($count novas)';
  }

  @override
  String get notificationsDeleted => 'Notificações excluídas.';

  @override
  String loadNotificationsError(Object error) {
    return 'Erro ao carregar notificações: $error';
  }

  @override
  String updateNotificationError(Object error) {
    return 'Erro ao atualizar notificação: $error';
  }

  @override
  String deleteNotificationError(Object error) {
    return 'Erro ao excluir notificação: $error';
  }

  @override
  String get markAllReadError => 'Não foi possível marcar todas como lidas';

  @override
  String get deleteAll => 'Excluir todas';

  @override
  String get deleteAllNotificationsError =>
      'Não foi possível excluir todas as notificações';

  @override
  String get sessionInvalidTitle => 'Sessão inválida';

  @override
  String get sessionInvalidPleaseLogin => 'Sessão inválida. Faça login.';

  @override
  String get notificationsNeedOwnerSubtitle =>
      'É necessária uma sessão ativa para ver notificações.';

  @override
  String get noNotificationsTitle => 'Sem notificações';

  @override
  String get noNotificationsSubtitle => 'Não há notificações disponíveis.';

  @override
  String get deleteNotificationTitle => 'Excluir notificação';

  @override
  String get deleteNotificationBody => 'Deseja excluir esta notificação?';

  @override
  String get deleteAllNotificationsTitle => 'Excluir todas';

  @override
  String get deleteAllNotificationsBody =>
      'Deseja excluir todas as notificações?';

  @override
  String get deleteAllNotificationsTooltip => 'Excluir todas';

  @override
  String get markAsRead => 'Marcar como lida';

  @override
  String get markAsUnread => 'Marcar como não lida';

  @override
  String get markAllAsReadTooltip => 'Marcar todas como lidas';

  @override
  String get institucionActividadCurricularGeneral => 'Atividade curricular';

  @override
  String get institucionActividadExtracurricularGeneral =>
      'Atividade extracurricular';

  @override
  String get institucionActividadExtracurricular => 'Extracurricular';

  @override
  String get institucionWorkProfileFallback => 'Perfil de trabalho';

  @override
  String get institucionChangeActivityTitle => 'Alterar atividade';

  @override
  String get institucionChangeActivityBody =>
      'Selecione a atividade que deseja gerenciar';

  @override
  String get institucionWorkProfileNameTitle => 'Nome do perfil';

  @override
  String get name => 'Nome';

  @override
  String get institucionWorkProfileNameHint => 'ex.: Administração, Direção';

  @override
  String get institucionWorkProfileNameInvalid => 'Nombre inválido.';

  @override
  String institucionAreaChip(Object area, Object who) {
    return '$area · $who';
  }

  @override
  String institucionAreaChipWithTtl(Object area, Object who, Object ttl) {
    return '$area · $who · $ttl';
  }

  @override
  String get institucionAreasFree => 'Áreas livres';

  @override
  String get planFallbackNoStructured => 'Plano sem estrutura detalhada';

  @override
  String get idNoSession => 'Sem sessão';

  @override
  String idWithValue(Object value) {
    return 'ID: $value';
  }

  @override
  String institucionPlanAndProfilesPerActivity(Object plan, Object max) {
    return 'Plano: $plan · Perfis: $max por atividade';
  }

  @override
  String get institucionFirstSelectActivityBody =>
      'Selecione primeiro uma atividade';

  @override
  String get institucionWorkProfilesAreInternalNote =>
      'Perfis de trabalho são internos';

  @override
  String get institucionNoActivitiesYet =>
      'Ainda não há atividades configuradas';

  @override
  String get institucionManageCurricularActivity =>
      'Gerenciar atividade curricular';

  @override
  String get institucionManageExtracurricularModule =>
      'Gerenciar módulo extracurricular';

  @override
  String institucionPlanAndAvailableProfiles(Object plan, Object max) {
    return 'Plano: $plan · Perfis disponíveis: $max';
  }

  @override
  String get institucionConcurrentProfilesRule =>
      'Perfis simultâneos conforme o plano';

  @override
  String get institucionWorkProfilesTitle => 'Perfis de trabalho';

  @override
  String get institucionWorkProfilesDescription => 'Gestão de perfis internos';

  @override
  String institucionProfileWorkingSubtitle(
    Object area,
    Object who,
    Object ttl,
  ) {
    return '$area · $who · $ttl';
  }

  @override
  String get institucionWorkProfilesRenameTip =>
      'Você pode renomear este perfil';

  @override
  String get institucionSelectActivityTitle => 'Selecionar atividade';

  @override
  String get institucionSelectWorkProfileTitle =>
      'Selecionar perfil de trabalho';

  @override
  String get institucionChangeActivityTooltip => 'Alterar atividade';

  @override
  String get institucionPlanTitle => 'Plano da instituição';

  @override
  String get institucionPlanHeader => 'Escolha seu plano';

  @override
  String get institucionPlanChooseYourPlanTitle => 'Escolha seu plano';

  @override
  String get institucionPlanChooseYourPlanSubtitle =>
      'Selecione o plano mais adequado';

  @override
  String get institucionPlanNoModulesSelected => 'Nenhum módulo selecionado.';

  @override
  String get institucionPlanInvalidInstitutionId => 'Instituição inválida.';

  @override
  String get institucionPlanPickAtLeastOneModule =>
      'Selecione ao menos um módulo.';

  @override
  String get institucionPlanChooseStandardOrPremium =>
      'Escolha Padrão ou Premium.';

  @override
  String get institucionPlanChooseBasicOrPremium =>
      'Escolha Básico ou Premium.';

  @override
  String get institucionPlanPromoCleared => 'Código removido';

  @override
  String get institucionPlanPromoSoldOut => 'Código esgotado';

  @override
  String get institucionPlanPromoReservedAlready => 'Código já reservado';

  @override
  String get institucionPlanPromoReserved => 'Código reservado';

  @override
  String get institucionPlanPromoInvalid => 'Código inválido';

  @override
  String institucionPlanPromoApplied(Object code) {
    return 'Promo aplicada: $code';
  }

  @override
  String get invalidEmail => 'Email inválido';

  @override
  String get invalidPassword => 'Senha inválida';

  @override
  String get institucionPlanCodeRequiredForFreeActivation =>
      'É necessário um código para ativar o plano gratuito';

  @override
  String get argentina => 'Argentina';

  @override
  String get emailAlreadyRegisteredLogin => 'Email já registrado. Faça login.';

  @override
  String institucionPlanTierLabel(Object tier, Object price) {
    return 'Plano $tier ($price)';
  }

  @override
  String get usdToArsTitle => 'Conversão USD → ARS';

  @override
  String get usdToArsSubtitleBestEffort => 'Estimativa de referência';

  @override
  String get usdToArsUnavailable => 'Conversão indisponível';

  @override
  String usdToArsValue(Object value) {
    return 'USD → ARS: $value';
  }

  @override
  String get usdToArsManualLabel => 'Cotação manual';

  @override
  String get usdToArsUsingManual => 'Usando cotação manual';

  @override
  String updatedAt(Object date) {
    return 'Atualizado em $date';
  }

  @override
  String get promoCodeTitle => 'Código promocional';

  @override
  String get promoCodeOptionalSubtitle => 'Opcional';

  @override
  String get promoCodeLabel => 'Código';

  @override
  String get promoCodeHint => 'Digite o código';

  @override
  String get iHavePromoCode => 'Tenho um código';

  @override
  String promoAppliedLine(Object code, Object label) {
    return 'Promo aplicada: $code · $label';
  }

  @override
  String get subtotalUsd => 'Subtotal (USD)';

  @override
  String get promoDiscountUsd => 'Desconto (USD)';

  @override
  String get totalUsd => 'Total (USD)';

  @override
  String get totalArs => 'Total (ARS)';

  @override
  String get institucionPlanSummarySubtitle => 'Resumo do plano';

  @override
  String get notAvailable => 'Indisponível';

  @override
  String get calcDetailsTitle => 'Detalhes do cálculo';

  @override
  String get calcDetailsSubtitle => 'Detalhamento de preços';

  @override
  String get institucionPlanNoteNoPaymentsYet =>
      'Pagamentos ainda não estão habilitados nesta fase';

  @override
  String get institucionGenericName => 'Instituição';

  @override
  String get countryArgentina => 'Argentina';

  @override
  String get institucionTitle => 'Instituição';

  @override
  String get actionRetry => 'Tentar novamente';

  @override
  String get actionBackHome => 'Voltar ao início';

  @override
  String get actionLogout => 'Sair';

  @override
  String get actionRefresh => 'Atualizar';

  @override
  String get actionExit => 'Sair';

  @override
  String get actionLoad => 'Carregar';

  @override
  String get actionSave => 'Salvar';

  @override
  String get actionSaving => 'Salvando...';

  @override
  String get statusSaving => 'Salvando...';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionEdit => 'Editar';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRequest => 'Solicitar';

  @override
  String get actionList => 'Listar';

  @override
  String get actionIncrease => 'Aumentar';

  @override
  String get actionDecrease => 'Diminuir';

  @override
  String get valueEmpty => 'Vazio';

  @override
  String get valueNone => 'Nenhum';

  @override
  String get labelNotProvided => 'Não informado';

  @override
  String get validationTooShort => 'Muito curto';

  @override
  String get validationCannotBeNegative => 'Não pode ser negativo';

  @override
  String get institucionAreaErrorLoadFailed =>
      'Não foi possível carregar a área operacional.';

  @override
  String get institucionAreaSnackNoInstitucion =>
      'Nenhuma instituição carregada.';

  @override
  String get institucionAreaDefaultWorkProfileName => 'Perfil de trabalho';

  @override
  String get institucionAreaSnackAreaInUse =>
      'Esta área está sendo usada por outro perfil.';

  @override
  String get institucionAreaDefaultActivityLabel => 'Atividade';

  @override
  String get institucionAreaTitle => 'Área operacional';

  @override
  String institucionAreaIdLine(Object id) {
    return 'ID: $id';
  }

  @override
  String institucionAreaLocationLine(Object location) {
    return 'Local: $location';
  }

  @override
  String institucionAreaActivityLine(Object activity) {
    return 'Atividade: $activity';
  }

  @override
  String institucionAreaWorkProfileLine(Object profile) {
    return 'Perfil: $profile';
  }

  @override
  String institucionAreaAccessLine(Object curricularOk, Object extraOk) {
    return 'Acesso: curricular $curricularOk · extracurricular $extraOk';
  }

  @override
  String get institucionAreaCardNotificationsTitle => 'Notificações';

  @override
  String get institucionAreaCardNotificationsSubtitle =>
      'Ver notificações da instituição';

  @override
  String get institucionAreaSemanticsOpenNotifications => 'Abrir notificações';

  @override
  String get institucionAreaCardSolicitudesTitle => 'Solicitações';

  @override
  String get institucionAreaCardSolicitudesSubtitle =>
      'Gerenciar solicitações de alunos';

  @override
  String get institucionAreaSemanticsOpenSolicitudes => 'Abrir solicitações';

  @override
  String get institucionAreaCardVacantesTitle => 'Vagas';

  @override
  String get institucionAreaCardVacantesSubtitle =>
      'Gerenciar grupos e capacidades';

  @override
  String get institucionAreaSemanticsOpenVacantes => 'Abrir vagas';

  @override
  String get institucionAreaCardVacantesLockedSubtitle =>
      'Indisponível neste plano';

  @override
  String get institucionAreaSemanticsVacantesLocked => 'Vagas indisponíveis';

  @override
  String get institucionAreaCardDocumentacionTitle => 'Documentação';

  @override
  String get institucionAreaCardDocumentacionSubtitle =>
      'Solicitar e revisar documentos';

  @override
  String get institucionAreaSemanticsOpenDocumentacion => 'Abrir documentação';

  @override
  String get institucionAreaCardExtraHubTitle => 'Extracurricular';

  @override
  String get institucionAreaCardExtraHubSubtitle =>
      'Gerenciar módulos extracurriculares';

  @override
  String get institucionAreaSemanticsOpenExtraHub => 'Abrir extracurricular';

  @override
  String get institucionAreaCardExtraHubLockedSubtitle =>
      'Indisponível neste plano';

  @override
  String get institucionAreaSemanticsExtraHubLocked =>
      'Extracurricular indisponível';

  @override
  String get institucionAreaCardCroquisTitle => 'Croqui';

  @override
  String get institucionAreaCardCroquisSubtitle => 'Gerenciar croqui da sala';

  @override
  String get institucionAreaSemanticsOpenCroquis => 'Abrir croqui';

  @override
  String get institucionAreaCardCroquisLockedSubtitle =>
      'Indisponível neste plano';

  @override
  String get institucionAreaSemanticsOpenCroquisLocked =>
      'Croquis no disponible';

  @override
  String get institucionAreaSnackMissingActivityScope =>
      'Primero seleccioná una actividad para operar.';

  @override
  String get institucionAreaMissingActivityHint =>
      'Falta seleccionar una actividad. Volvé y elegí una para habilitar las acciones.';

  @override
  String get turnoMorning => 'Manhã';

  @override
  String get croquisTitle => 'Croqui da sala';

  @override
  String get croquisTurnoMorning => 'Mañana';

  @override
  String get croquisTurnoAfternoon => 'Tarde';

  @override
  String get croquisTurnoNight => 'Noche';

  @override
  String get croquisTurnoFullDay => 'Jornada completa';

  @override
  String get croquisSnackInvalidInstitution => 'Instituição inválida.';

  @override
  String get croquisSnackEnterAulaBeforeSave =>
      'Digite o nome da sala antes de salvar.';

  @override
  String get croquisSnackSaved => 'Croqui salvo.';

  @override
  String croquisSnackSaveError(Object error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get croquisDialogClearTitle => 'Limpar grade';

  @override
  String get croquisDialogClearBody => 'Deseja limpar toda a grade?';

  @override
  String get croquisDialogCellTitle => 'Célula';

  @override
  String get croquisFieldNameLabel => 'Nome';

  @override
  String get croquisDialogNewGroupTitle => 'Novo grupo';

  @override
  String get croquisFieldGroupTitleLabel => 'Nome do grupo';

  @override
  String get croquisFieldGroupColorLabel => 'Cor do grupo';

  @override
  String get croquisFieldGroupColorHint => 'Escolha uma cor';

  @override
  String get croquisFieldRowLabel => 'Linha';

  @override
  String get croquisFieldColLabel => 'Coluna';

  @override
  String get croquisFieldHeightLabel => 'Altura';

  @override
  String get croquisFieldWidthLabel => 'Largura';

  @override
  String get croquisDialogDeleteGroupTitle => 'Excluir grupo';

  @override
  String get croquisDialogDeleteGroupBody => 'Deseja excluir este grupo?';

  @override
  String get croquisDialogUnsavedTitle => 'Alterações não salvas';

  @override
  String get croquisDialogUnsavedBody =>
      'Você tem alterações não salvas. Sair mesmo assim?';

  @override
  String get croquisErrorInit => 'Erro ao inicializar o croqui.';

  @override
  String get croquisSectionAulaTurno => 'Sala e turno';

  @override
  String get croquisFieldAulaLabel => 'Sala';

  @override
  String get croquisFieldAulaHint => 'ex.: Sala 1 / 3B';

  @override
  String get croquisFieldTurnoLabel => 'Turno';

  @override
  String get croquisActionClearGrid => 'Limpar grade';

  @override
  String get croquisActionAddGroup => 'Adicionar grupo';

  @override
  String get croquisTipTapCellAutosave =>
      'Toque em uma célula para editar. Salva automaticamente.';

  @override
  String get croquisSectionGrid => 'Grade';

  @override
  String croquisGridSizeLine(Object rows, Object cols) {
    return 'Tamanho: $rows×$cols';
  }

  @override
  String get croquisSectionGroups => 'Grupos';

  @override
  String get croquisGroupsEmpty => 'Nenhum grupo criado.';

  @override
  String get croquisGroupFallbackTitle => 'Grupo';

  @override
  String croquisGroupSubtitle(Object count) {
    return 'Membros: $count';
  }

  @override
  String get institucionDocsWarnPerfilButNoOwner =>
      'Perfil presente, mas owner ausente. Visão limitada.';

  @override
  String get institucionDocsWarnOwnerButNoPerfil =>
      'Owner presente, mas perfil ausente. Visão limitada.';

  @override
  String get institucionDocsErrorInvalidInstitutionId =>
      'ID de instituição inválido.';

  @override
  String get institucionDocsSnackInvalidInstitutionEmptyId =>
      'ID de instituição vazio.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfil =>
      'Owner e perfil são obrigatórios para esta ação.';

  @override
  String get institucionDocsSnackNoDocTypes =>
      'Nenhum tipo de documento disponível.';

  @override
  String get institucionDocsSnackSolicitudCreated => 'Solicitação criada.';

  @override
  String get institucionDocsSnackNeedOwnerAndPerfilToUpload =>
      'Owner e perfil são obrigatórios para simular upload.';

  @override
  String get institucionDocsSnackMissingRef => 'Referência de arquivo ausente.';

  @override
  String get institucionDocsSnackTempDocSaved => 'Documento temporário salvo.';

  @override
  String get institucionDocsSnackNeedPerfilToCleanup =>
      'Perfil é obrigatório para limpar expirados.';

  @override
  String get institucionDocsSnackNoExpiredToRemove =>
      'Não há expirados para remover.';

  @override
  String institucionDocsSnackExpiredRemoved(Object count) {
    return 'Removidos $count expirados.';
  }

  @override
  String get institucionDocsDialogDeleteTitle => 'Excluir';

  @override
  String institucionDocsDialogDeleteBody(Object name) {
    return 'Excluir este item: $name?';
  }

  @override
  String get institucionDocsSnackExpiredUseCleanup =>
      'Expirado. Use limpar expirados.';

  @override
  String get institucionDocsSnackDeleted => 'Excluído.';

  @override
  String get institucionDocsSnackCannotOpenMissingIds =>
      'Não é possível abrir: IDs ausentes.';

  @override
  String get institucionDocsSnackDeeplinkTooLong => 'Deeplink muito longo.';

  @override
  String get institucionDocsSnackRouteNotRegistered => 'Rota não registrada.';

  @override
  String get estadoSolicitudPendiente => 'Pendente';

  @override
  String get estadoSolicitudCumplida => 'Cumprida';

  @override
  String get estadoSolicitudCancelada => 'Cancelada';

  @override
  String get estadoDocumentoExpirado => 'Expirado';

  @override
  String get estadoDocumentoActivo => 'Ativo';

  @override
  String get institucionDocsTooltipOpenAlumno => 'Abrir aluno';

  @override
  String get institucionDocsTooltipExpiredUseCleanup =>
      'Expirado (use limpeza)';

  @override
  String get institucionDocsViewAllInstitution => 'Ver tudo (instituição)';

  @override
  String get institucionDocsViewFilteredOwnerPerfil =>
      'Filtrado (owner+perfil)';

  @override
  String get institucionDocsViewFilteredPerfil => 'Filtrado (perfil)';

  @override
  String get institucionDocsViewFilteredOwner => 'Filtrado (owner)';

  @override
  String institucionDocsInstitutionIdLine(Object id) {
    return 'Instituição: $id';
  }

  @override
  String institucionDocsInstitutionOwnerLine(Object owner) {
    return 'Owner: $owner';
  }

  @override
  String get institucionDocsFieldOwnerAlumnoLabel => 'Owner do aluno';

  @override
  String get institucionDocsFieldPerfilAlumnoLabel => 'Perfil do aluno';

  @override
  String get institucionDocsFieldTipoDocumentoLabel => 'Tipo de documento';

  @override
  String get institucionDocsFieldMensajeOpcionalLabel => 'Mensagem (opcional)';

  @override
  String get institucionDocsFieldRefLabel => 'Referência';

  @override
  String get institucionDocsFieldTtlDaysLabel => 'TTL (dias)';

  @override
  String get institucionDocsActionSimulateUpload => 'Simular upload';

  @override
  String get institucionDocsActionCleanupExpired => 'Limpar expirados';

  @override
  String get institucionDocsEmptySolicitudes => 'Sem solicitações.';

  @override
  String get institucionDocsEmptyDocumentos => 'Sem documentos.';

  @override
  String institucionDocsSolicitudTipoLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String institucionDocsSolicitudSubtitle(Object estado, Object fecha) {
    return '$estado · $fecha';
  }

  @override
  String institucionDocsDocumentoTipoLine(Object tipo) {
    return 'Tipo: $tipo';
  }

  @override
  String institucionDocsDocumentoSubtitle(Object estado, Object vence) {
    return '$estado · $vence';
  }

  @override
  String institucionDocsAppBarTitle(Object institucion) {
    return '$institucion – Documentação';
  }

  @override
  String get tabSolicitudes => 'Solicitações';

  @override
  String get tabDocumentos => 'Documentos';

  @override
  String get institucionDocsErrorTimeout =>
      'Tiempo de espera agotado. Intentá nuevamente.';

  @override
  String get institucionExtracGrupoGuiaBloqueTitle => 'Guia do bloco';

  @override
  String get institucionExtracGrupoInvalidInstitutionId =>
      'Instituição inválida.';

  @override
  String institucionExtracGrupoWarnModuleKeyMismatch(Object expected) {
    return 'moduleKey não corresponde ao esperado: $expected';
  }

  @override
  String institucionExtracGrupoWarnModuleKeyNotCanonical(Object value) {
    return 'moduleKey não canônica: $value';
  }

  @override
  String institucionExtracGrupoSaveFailed(Object error) {
    return 'Não foi possível salvar: $error';
  }

  @override
  String get institucionExtracGrupoEditTitle => 'Editar grupo';

  @override
  String get institucionExtracGrupoCreateTitle => 'Criar grupo';

  @override
  String institucionExtracGrupoHeaderBloqueLine(
    Object bloque,
    Object moduleKey,
  ) {
    return 'Bloco: $bloque · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracGrupoHeaderNotePrototype =>
      'Protótipo (sem backend)';

  @override
  String institucionExtracGrupoWarnKeyMismatch(Object expected) {
    return 'Chave não corresponde ao esperado: $expected';
  }

  @override
  String institucionExtracGrupoWarnKeyNotCanonical(Object value) {
    return 'Chave não canônica: $value';
  }

  @override
  String get institucionExtracGrupoFieldActividadLabel => 'Atividade';

  @override
  String get institucionExtracGrupoFieldActividadHint => 'ex.: Futebol';

  @override
  String get institucionExtracGrupoValActividadRequired =>
      'Atividade é obrigatória';

  @override
  String get institucionExtracGrupoFieldGrupoLabel => 'Grupo';

  @override
  String get institucionExtracGrupoFieldGrupoHint => 'ex.: Grupo A';

  @override
  String get institucionExtracGrupoValGrupoRequired => 'Grupo é obrigatório';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalLabel =>
      'Turno (opcional)';

  @override
  String get institucionExtracGrupoFieldTurnoOptionalHint => 'ex.: Manhã';

  @override
  String get institucionExtracGrupoFieldAulaOptionalLabel => 'Sala (opcional)';

  @override
  String get institucionExtracGrupoFieldAulaOptionalHint => 'ex.: Ginásio';

  @override
  String get institucionExtracGrupoFieldCupoMaxLabel => 'Capacidade máxima';

  @override
  String get institucionExtracGrupoFieldCupoMaxHint => 'ex.: 25';

  @override
  String get institucionExtracGrupoFieldCupoOcupadoLabel => 'Ocupadas';

  @override
  String get institucionExtracGrupoValOccExceedsMax =>
      'Ocupadas não pode exceder o máximo';

  @override
  String get institucionExtracGrupoFieldActivoTitle => 'Ativo';

  @override
  String get institucionExtracGrupoFieldActivoSubtitle =>
      'Permite solicitações';

  @override
  String get institucionExtracBaseErrInvalidInstId => 'Instituição inválida.';

  @override
  String get institucionExtracBaseErrInvalidModuleKeySnake =>
      'moduleKey inválida (snake_case).';

  @override
  String institucionExtracBaseErrModuleKeyMismatch(Object expected) {
    return 'moduleKey não corresponde ao esperado: $expected';
  }

  @override
  String institucionExtracBaseErrModuleKeyNotCanonical(Object value) {
    return 'moduleKey não canônica: $value';
  }

  @override
  String get institucionExtracBaseCuposNotManaged =>
      'Capacidades não gerenciadas';

  @override
  String institucionExtracBaseCuposManaged(Object disp, Object max) {
    return 'Disponíveis: $disp de $max';
  }

  @override
  String get institucionExtracBaseInvalidDataGeneric => 'Dados inválidos.';

  @override
  String get institucionExtracBaseInvalidDataForCupos =>
      'Dados inválidos para capacidades.';

  @override
  String get institucionExtracBaseCuposRequireMax =>
      'Capacidade máxima é obrigatória.';

  @override
  String get institucionExtracBaseCuposDialogTitle => 'Editar capacidades';

  @override
  String institucionExtracBaseCuposDialogActividad(Object actividad) {
    return 'Atividade: $actividad';
  }

  @override
  String institucionExtracBaseCuposDialogGrupo(Object grupo) {
    return 'Grupo: $grupo';
  }

  @override
  String institucionExtracBaseCuposDialogMax(Object max) {
    return 'Máx: $max';
  }

  @override
  String institucionExtracBaseCuposDialogOcupado(Object ocupado) {
    return 'Ocupadas: $ocupado';
  }

  @override
  String institucionExtracBaseCuposDialogDisponibles(Object disp) {
    return 'Disponíveis: $disp';
  }

  @override
  String get institucionExtracBaseCuposUpdated => 'Capacidades atualizadas.';

  @override
  String institucionExtracBaseCuposSaveFailed(Object error) {
    return 'Não foi possível salvar capacidades: $error';
  }

  @override
  String get institucionExtracBaseInvalidDataForDelete =>
      'Não é possível excluir: dados inválidos.';

  @override
  String get institucionExtracBaseDeleteDialogTitle => 'Excluir grupo';

  @override
  String institucionExtracBaseDeleteDialogBody(Object actividad, Object grupo) {
    return 'Excluir $actividad ($grupo)?';
  }

  @override
  String get institucionExtracBaseDeletedOk => 'Excluído.';

  @override
  String institucionExtracBaseDeleteFailed(Object error) {
    return 'Não foi possível excluir: $error';
  }

  @override
  String institucionExtracBaseAppBarTitle(Object module) {
    return '$module';
  }

  @override
  String institucionExtracBaseChipModuleKey(Object key) {
    return 'moduleKey: $key';
  }

  @override
  String institucionExtracBaseChipInstId(Object id) {
    return 'Instituição: $id';
  }

  @override
  String get institucionExtracBaseHeaderNote => 'Gestão do módulo (protótipo)';

  @override
  String get institucionExtracBaseQuickGuideTitle => 'Guia rápido';

  @override
  String get institucionExtracBaseQuickGuideEmpty => 'Nenhum guia disponível.';

  @override
  String get institucionExtracBaseQuickGuideFootnote => 'Textos podem mudar.';

  @override
  String get institucionExtracBaseGroupsTitle => 'Grupos';

  @override
  String get institucionExtracBaseInvalidDataToList =>
      'Não é possível listar: dados inválidos.';

  @override
  String get institucionExtracBaseLoadFailed => 'Não foi possível carregar.';

  @override
  String get institucionExtracBaseNoGroupsYet => 'Ainda não há grupos.';

  @override
  String get institucionExtracBaseWithCupos => 'Com capacidades';

  @override
  String get institucionExtracBaseNoCupos => 'Sem capacidades';

  @override
  String institucionExtracBaseGroupLine(Object group) {
    return 'Grupo: $group';
  }

  @override
  String institucionExtracBaseTurnoLine(Object turno) {
    return 'Turno: $turno';
  }

  @override
  String institucionExtracBaseAulaLine(Object aula) {
    return 'Sala: $aula';
  }

  @override
  String get institucionExtracBaseActionCupos => 'Capacidades';

  @override
  String get institucionExtracBaseCreateGroupTitle => 'Criar grupo';

  @override
  String get institucionExtracBaseCreateGroupSubtitle =>
      'Adicionar um novo grupo';

  @override
  String get institucionExtracBaseRulesTitle => 'Regras';

  @override
  String get institucionExtracBaseRulesSubtitle => 'Pendente';

  @override
  String institucionExtracBaseRulesPendingToast(Object value) {
    return 'Regras pendentes: $value';
  }

  @override
  String get institucionExtracBaseSolicitudesTitle => 'Solicitações';

  @override
  String institucionExtracBaseSolicitudesSubtitle(Object moduleKey) {
    return 'Ver solicitações do módulo: $moduleKey';
  }

  @override
  String get institucionExtracHubTitle => 'Extracurricular';

  @override
  String institucionExtracHubHeaderInstOk(Object instIdCanon) {
    return 'Instituição: $instIdCanon';
  }

  @override
  String get institucionExtracHubHeaderInstInvalid => 'Instituição inválida.';

  @override
  String get institucionExtracHubIntro => 'Selecione um módulo para gerenciar.';

  @override
  String get institucionExtracHubInvalidInstIdHelp =>
      'Volte e tente novamente com uma instituição válida.';

  @override
  String institucionExtracHubTileSubtitle(
    Object descripcion,
    Object moduleKey,
  ) {
    return '$descripcion · moduleKey: $moduleKey';
  }

  @override
  String get institucionExtracHubToastInvalidInstId => 'Instituição inválida.';

  @override
  String institucionExtracHubToastInvalidModuleKey(Object bloque) {
    return 'Não foi possível abrir o módulo: $bloque';
  }

  @override
  String errorLoadingGroups(Object error) {
    return 'Erro ao carregar grupos: $error';
  }

  @override
  String errorSaving(Object error) {
    return 'Erro ao salvar: $error';
  }

  @override
  String get occupiedRecalculatedOk => 'Ocupadas recalculadas.';

  @override
  String errorRecalculating(Object error) {
    return 'Erro ao recalcular: $error';
  }

  @override
  String get groupNameLabel => 'Nome do grupo';

  @override
  String get activityLabelShort => 'Atividade';

  @override
  String get maxCapacityLabel => 'Capacidade máxima';

  @override
  String get completeRequiredFields => 'Complete os campos obrigatórios.';

  @override
  String get commonRefresh => 'Atualizar';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Excluir';

  @override
  String get commonNo => 'Não';

  @override
  String get commonNone => 'Nenhum';

  @override
  String get commonProfile => 'Perfil';

  @override
  String get commonModule => 'Módulo';

  @override
  String get commonPending => 'Pendente';

  @override
  String get commonCompleted => 'Concluída';

  @override
  String get commonCancelled => 'Cancelada';

  @override
  String get commonConfirmed => 'Confirmada';

  @override
  String get commonRejected => 'Rejeitada';

  @override
  String get commonExpired => 'Expirado';

  @override
  String get commonActive => 'Ativo';

  @override
  String get commonCurricular => 'Curricular';

  @override
  String get commonExtracurricular => 'Extracurricular';

  @override
  String get commonInstitution => 'Instituição';

  @override
  String get commonType => 'Tipo';

  @override
  String get commonClassGroup => 'Turma/Grupo';

  @override
  String get commonShift => 'Turno';

  @override
  String get commonStatus => 'Status';

  @override
  String get commonGenerating => 'Gerando…';

  @override
  String commonErrorWithDetails(Object error) {
    return 'Erro: $error';
  }

  @override
  String get alumnoDocumentosTitle => 'Documentação';

  @override
  String get alumnoDocumentosInvalidOwner => 'Owner inválido.';

  @override
  String get alumnoDocumentosInvalidPerfil => 'Perfil inválido.';

  @override
  String get alumnoDocumentosOwnerMismatchAutoscrollIgnored =>
      'Este deeplink pertence a outra conta. Rolagem automática ignorada.';

  @override
  String get alumnoDocumentosDeeplinkSolicitudNotFound =>
      'Solicitação do deeplink não encontrada.';

  @override
  String get alumnoDocumentosDeeplinkDocumentoNotFound =>
      'Documento do deeplink não encontrado.';

  @override
  String get alumnoDocumentosEmptySolicitudes => 'Sem solicitações.';

  @override
  String get alumnoDocumentosEmptyDocumentos => 'Sem documentos.';

  @override
  String get alumnoDocumentosFieldMensaje => 'Mensagem';

  @override
  String get alumnoDocumentosFieldTipo => 'Tipo';

  @override
  String get alumnoDocumentosFieldId => 'ID';

  @override
  String get alumnoDocumentosFieldEstado => 'Status';

  @override
  String get alumnoDocumentosFieldInstitucion => 'Instituição';

  @override
  String get alumnoDocumentosFieldCreada => 'Criada';

  @override
  String get alumnoDocumentosFieldOwner => 'Owner';

  @override
  String get alumnoDocumentosFieldPerfil => 'Perfil';

  @override
  String get alumnoDocumentosFieldSubido => 'Enviado';

  @override
  String get alumnoDocumentosFieldExpira => 'Expira';

  @override
  String get alumnoDocumentosExpiredWillBeDeletedOnClean =>
      'será excluído ao limpar expirados';

  @override
  String get alumnoDocumentosFieldSolicitud => 'Solicitação';

  @override
  String get alumnoDocumentosFieldRef => 'Referência';

  @override
  String get alumnoDocumentosNoExpiredToClean =>
      'Não há expirados para limpar.';

  @override
  String alumnoDocumentosExpiredCleanedCount(Object count) {
    return 'Limpados $count expirados.';
  }

  @override
  String get alumnoDocumentosDocExpiredUseClean =>
      'Este documento está expirado. Use “Limpar expirados”.';

  @override
  String get alumnoDocumentosExpiredTooltip => 'Expirado (use limpeza)';

  @override
  String get alumnoDocumentosDeleteDocTitle => 'Excluir documento';

  @override
  String alumnoDocumentosDeleteDocBody(Object id) {
    return 'Excluir documento $id?';
  }

  @override
  String get alumnoDocumentosDocDeleted => 'Documento excluído.';

  @override
  String get alumnoDocumentosCleanExpired => 'Limpar expirados';

  @override
  String get alumnoDocumentosTabSolicitudes => 'Solicitações';

  @override
  String get alumnoDocumentosTabDocumentos => 'Documentos';

  @override
  String get alumnoMisSolicitudesTitleOwner => 'Minhas solicitações';

  @override
  String alumnoMisSolicitudesTitlePerfil(Object perfil) {
    return 'Solicitações – $perfil';
  }

  @override
  String get alumnoMisSolicitudesInvalidOwner => 'Owner inválido.';

  @override
  String get alumnoMisSolicitudesInvalidPerfil => 'Perfil inválido.';

  @override
  String alumnoMisSolicitudesLoadError(Object error) {
    return 'Erro ao carregar: $error';
  }

  @override
  String get alumnoMisSolicitudesStatusCancelledYou => 'Cancelada por você';

  @override
  String get alumnoMisSolicitudesStatusCancelledInstitution =>
      'Cancelada pela instituição';

  @override
  String get alumnoMisSolicitudesNotPending =>
      'Esta solicitação não está mais pendente.';

  @override
  String get alumnoMisSolicitudesCancelTitle => 'Cancelar solicitação';

  @override
  String get alumnoMisSolicitudesCancelBody =>
      'Deseja cancelar esta solicitação?';

  @override
  String get alumnoMisSolicitudesCancelCta => 'Cancelar';

  @override
  String get alumnoMisSolicitudesCancelledOk => 'Solicitação cancelada.';

  @override
  String alumnoMisSolicitudesCancelError(Object error) {
    return 'Não foi possível cancelar: $error';
  }

  @override
  String get alumnoMisSolicitudesDeleteTitle => 'Excluir solicitação';

  @override
  String get alumnoMisSolicitudesDeleteBody =>
      'Deseja excluir esta solicitação? (somente curricular pendente)';

  @override
  String get alumnoMisSolicitudesDeletedOk => 'Solicitação excluída.';

  @override
  String get alumnoMisSolicitudesCanonicalContextMissing =>
      'Falta contexto canônico (owner/perfil) para gerar o PDF.';

  @override
  String alumnoMisSolicitudesPdfGenerated(Object path) {
    return 'PDF gerado: $path';
  }

  @override
  String alumnoMisSolicitudesPdfError(Object error) {
    return 'Não foi possível gerar o PDF: $error';
  }

  @override
  String get alumnoMisSolicitudesDownloadPdf => 'Baixar PDF';

  @override
  String alumnoMisSolicitudesTabPendingCount(Object count) {
    return 'Pendentes ($count)';
  }

  @override
  String alumnoMisSolicitudesTabConfirmedCount(Object count) {
    return 'Confirmadas ($count)';
  }

  @override
  String alumnoMisSolicitudesTabRejectedCount(Object count) {
    return 'Rejeitadas ($count)';
  }

  @override
  String alumnoMisSolicitudesTabCancelledCount(Object count) {
    return 'Canceladas ($count)';
  }

  @override
  String get alumnoMisSolicitudesEmptySection =>
      'Não há solicitações nesta seção.';

  @override
  String get alumnoMisSolicitudesEmptyPending =>
      'Você não tem solicitações pendentes.';

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonSave => 'Salvar';

  @override
  String get commonSaving => 'Salvando…';

  @override
  String get commonGenericError => 'Erro.';

  @override
  String get commonEmail => 'Email';

  @override
  String get commonEmailRequired => 'Digite seu email.';

  @override
  String get commonEmailInvalid => 'Email inválido.';

  @override
  String get commonPassword => 'Senha';

  @override
  String get commonNewPassword => 'Nova senha';

  @override
  String get commonConfirmPassword => 'Confirmar senha';

  @override
  String get commonPasswordsDontMatch => 'As senhas não coincidem.';

  @override
  String get commonShowPassword => 'Mostrar senha';

  @override
  String get commonHidePassword => 'Ocultar senha';

  @override
  String get commonRememberMe => 'Lembrar-me';

  @override
  String get commonSignIn => 'Entrar';

  @override
  String get commonSigningIn => 'Entrando…';

  @override
  String get commonRegister => 'Registrar';

  @override
  String get commonPasswordMinLength4 =>
      'A senha deve ter pelo menos 4 caracteres.';

  @override
  String get commonCreateAccount => 'Criar conta';

  @override
  String get commonCreating => 'Criando…';

  @override
  String get commonFeatureUnavailablePrototype =>
      'Este recurso não está disponível neste protótipo.';

  @override
  String get alumnoLoginAppBar => 'Acesso de alunos';

  @override
  String get alumnoLoginTitle => 'Entrar';

  @override
  String get alumnoLoginForgotPassword => 'Esqueci minha senha';

  @override
  String get alumnoLoginRegistroNoDisponible => 'Registro não disponível.';

  @override
  String get alumnoRegistroAppBar => 'Criar conta';

  @override
  String get alumnoRegistroTitle => 'Criar conta';

  @override
  String get alumnoRegistroPasswordRequired => 'Digite uma senha.';

  @override
  String get alumnoForgotPasswordTitle => 'Redefinir senha';

  @override
  String get alumnoForgotPasswordIntro =>
      'Digite seu email e escolha uma nova senha.';

  @override
  String get alumnoForgotPasswordEmailLabel => 'Email';

  @override
  String get alumnoForgotPasswordNewPasswordLabel => 'Nova senha';

  @override
  String get alumnoForgotPasswordConfirmPasswordLabel => 'Confirmar senha';

  @override
  String get alumnoForgotPasswordShowPassword => 'Mostrar senha';

  @override
  String get alumnoForgotPasswordHidePassword => 'Ocultar senha';

  @override
  String get alumnoForgotPasswordEnterEmailError => 'Digite seu email.';

  @override
  String get alumnoForgotPasswordInvalidEmailError => 'Email inválido.';

  @override
  String get alumnoForgotPasswordEnterPasswordError => 'Digite uma senha.';

  @override
  String get alumnoForgotPasswordPasswordTooShortError => 'Senha muito curta.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatchError =>
      'As senhas não coincidem.';

  @override
  String get alumnoForgotPasswordPasswordsDontMatch =>
      'Las contraseñas no coinciden.';

  @override
  String get alumnoForgotPasswordAccountNotFound =>
      'Nenhuma conta encontrada para este email.';

  @override
  String get alumnoForgotPasswordPasswordUpdatedPrototype =>
      'Senha atualizada (protótipo).';

  @override
  String get institucionForgotPasswordTitle => 'Redefinir senha';

  @override
  String get institucionForgotPasswordIntro =>
      'Digite o email da instituição e escolha uma nova senha.';

  @override
  String get institucionForgotPasswordEnterEmailError => 'Digite o email.';

  @override
  String get institucionForgotPasswordInvalidEmailError => 'Email inválido.';

  @override
  String get institucionForgotPasswordEnterPasswordError => 'Digite uma senha.';

  @override
  String get institucionForgotPasswordPasswordTooShortError =>
      'Senha muito curta.';

  @override
  String get institucionForgotPasswordPasswordsDontMatchError =>
      'As senhas não coincidem.';

  @override
  String get institucionForgotPasswordAccountNotFound =>
      'Nenhuma instituição encontrada para este email.';

  @override
  String get institucionForgotPasswordPasswordUpdatedPrototype =>
      'Senha atualizada (protótipo).';

  @override
  String get invalidOwner => 'Owner inválido.';

  @override
  String get noNotifications => 'Sem notificações.';

  @override
  String get onlyUnread => 'Apenas não lidas';

  @override
  String get showAll => 'Mostrar todas';

  @override
  String get allProfiles => 'Todos os perfis';

  @override
  String get filterByProfile => 'Filtrar por perfil';

  @override
  String get filterForcedByCaller =>
      'Filtro forzado por la pantalla de origen (no modificable desde aquí).';

  @override
  String get clearPerfilFilter => 'Limpar filtro de perfil';

  @override
  String get noResultsForFilter => 'Sem resultados para este filtro.';

  @override
  String get notificationDeleted => 'Notificação excluída.';

  @override
  String get notificationNoDestination => 'Esta notificação não tem destino.';

  @override
  String get invalidDeeplink => 'Deeplink inválido.';

  @override
  String get deeplinkOwnerMismatch => 'Este deeplink pertence a outra conta.';

  @override
  String get missingPerfilIdForOpen =>
      'Falta perfilId para abrir este destino.';

  @override
  String deeplinkNotSupported(Object path) {
    return 'Deeplink não suportado: $path';
  }

  @override
  String notificationPerfilLine(Object perfil) {
    return 'Perfil: $perfil';
  }

  @override
  String get institucionAreaErrorEmptyId => 'ID de instituição vazio.';

  @override
  String get alumnoGrupoExtraInvalidInstitution => 'Instituição inválida.';

  @override
  String get alumnoGrupoExtraMissingOwnerPerfil =>
      'Falta contexto de sessão (owner/perfil).';

  @override
  String get alumnoGrupoExtraTitle => 'Grupos extracurriculares';

  @override
  String get alumnoGrupoExtraLoadErrorTitle => 'Não foi possível carregar';

  @override
  String get alumnoGrupoExtraSearchHint => 'Buscar atividade ou instituição…';

  @override
  String get alumnoGrupoExtraBlockOptionalLabel => 'Bloco (opcional)';

  @override
  String get alumnoGrupoExtraEmptyFiltered =>
      'Nenhum grupo encontrado para este filtro.';

  @override
  String get alumnoGrupoExtraCupoUnmanaged => 'Capacidades não gerenciadas';

  @override
  String alumnoGrupoExtraOpenSolicitudError(Object error) {
    return 'Não foi possível abrir Solicitações: $error';
  }

  @override
  String alumnoGrupoExtraCupoManaged(Object disp, Object max) {
    return 'Disponíveis: $disp de $max';
  }

  @override
  String alumnoGrupoExtraSemanticsItem(
    Object actividad,
    Object institucion,
    Object cupo,
  ) {
    return '$actividad · $institucion · $cupo';
  }

  @override
  String get commonYes => 'Sí';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonSearch => 'Buscar';

  @override
  String get commonSearchHint => 'Buscar…';

  @override
  String get commonOptional => 'Opcional';

  @override
  String get commonRequired => 'Obligatorio';

  @override
  String get commonDeletePhotoTitle => 'Eliminar foto';

  @override
  String get commonDeletePhotoConfirm => '¿Querés eliminar esta foto?';

  @override
  String get commonNotificationsTooltip => 'Ver notificações';

  @override
  String get commonBackToProfiles => 'Voltar aos perfis';

  @override
  String get commonEmailLabel => 'Email';

  @override
  String get commonPhoneLabel => 'Telefone';

  @override
  String get commonChangePhoto => 'Alterar foto';

  @override
  String get commonDeletePhoto => 'Excluir foto';

  @override
  String get commonCalendar => 'Calendário';

  @override
  String get commonDocumentsPdf => 'Documentos (PDF)';

  @override
  String get commonStudentPdfSub => 'Ficha do aluno';

  @override
  String get commonNotifications => 'Notificações';

  @override
  String get commonLogout => 'Sair';

  @override
  String get commonPendingConnect => 'Conexão pendente';

  @override
  String get commonPasteRealScreenHint =>
      'Cole esta tela em um dispositivo real';

  @override
  String get commonSelectDate => 'Selecionar data';

  @override
  String get commonInvalidSessionAccountId => 'Sessão inválida (accountId)';

  @override
  String get commonNameLabel => 'Nome';

  @override
  String get commonEnterName => 'Digite o nome';

  @override
  String get commonLastNameLabel => 'Sobrenome';

  @override
  String get commonEnterLastName => 'Digite o sobrenome';

  @override
  String get commonEmailOptionalLabel => 'Email (opcional)';

  @override
  String get commonInvalidEmail => 'Email inválido';

  @override
  String get commonPhoneOptionalLabel => 'Telefone (opcional)';

  @override
  String get commonSaveProfile => 'Salvar perfil';

  @override
  String get commonClear => 'Limpiar';

  @override
  String get commonAll => 'Todos';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get commonLoadMore => 'Carregar mais';

  @override
  String get commonEndOfResults => 'Fim dos resultados';

  @override
  String get commonOwnerInvalid => 'Owner inválido';

  @override
  String get commonPerfilInvalid => 'Perfil inválido';

  @override
  String get commonDeleteTitle => 'Excluir';

  @override
  String get commonEvent => 'Evento';

  @override
  String get commonPersonal => 'Pessoal';

  @override
  String get commonDate => 'Data';

  @override
  String get commonSpecialEvent => 'Evento especial';

  @override
  String get commonId => 'ID';

  @override
  String get commonMandatory => 'Obrigatório';

  @override
  String get commonDetail => 'Detalhe';

  @override
  String get commonAttendance => 'Presença';

  @override
  String get commonAttendancePending => 'Pendente';

  @override
  String get commonAttendanceYes => 'Presente';

  @override
  String get commonAttendanceMaybe => 'Talvez';

  @override
  String get commonAttendanceNo => 'Ausente';

  @override
  String get commonPolicy => 'Política';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonMaybe => 'Talvez';

  @override
  String get commonDecline => 'Recusar';

  @override
  String get commonPrevMonth => 'Mês anterior';

  @override
  String get commonNextMonth => 'Próximo mês';

  @override
  String get commonEvents => 'Eventos';

  @override
  String get commonAlarm => 'Alarme';

  @override
  String get commonNoTime => 'Sem horário';

  @override
  String get commonEdit => 'Editar';

  @override
  String get commonNew => 'Novo';

  @override
  String get commonTitle => 'Título';

  @override
  String get commonNoteOptional => 'Nota (opcional)';

  @override
  String get commonTime => 'Hora';

  @override
  String get commonChoose => 'Escolher';

  @override
  String get commonView => 'Ver';

  @override
  String get commonShare => 'Compartilhar';

  @override
  String get commonGroup => 'Grupo';

  @override
  String get commonInstitutionUnavailable => 'Instituição indisponível';

  @override
  String get commonRequestCreated => 'Solicitação criada';

  @override
  String commonScheduleLabel(Object value) {
    return 'Horário: $value';
  }

  @override
  String commonAgeLabel(Object value) {
    return 'Idade: $value';
  }

  @override
  String commonSlotsLabel(Object value) {
    return 'Vagas: $value';
  }

  @override
  String commonProfileLabel(Object value) {
    return 'Perfil: $value';
  }

  @override
  String commonInstitutionLabel(Object value) {
    return 'Instituição: $value';
  }

  @override
  String commonActivityLabel(Object value) {
    return 'Atividade: $value';
  }

  @override
  String commonTypeLabel(Object value) {
    return 'Tipo: $value';
  }

  @override
  String commonModuleKeyLabel(Object value) {
    return 'moduleKey: $value';
  }

  @override
  String commonAulaGrupoLabel(Object value) {
    return 'Sala / Grupo: $value';
  }

  @override
  String commonShiftOrScheduleLabel(Object value) {
    return 'Turno ou horário: $value';
  }

  @override
  String get commonSend => 'Enviar';

  @override
  String get commonSending => 'Enviando…';

  @override
  String get commonRequestSentOk => 'Solicitação enviada com sucesso';

  @override
  String get commonError => 'Erro';

  @override
  String get commonCreate => 'Criar';

  @override
  String get commonFieldRequired => 'Campo obrigatório';

  @override
  String get commonTooShort => 'Muito curto';

  @override
  String get commonPhone => 'Telefone';

  @override
  String get commonPhoneInvalid => 'Telefone inválido';

  @override
  String get commonRemove => 'Remover';

  @override
  String get commonAdd => 'Adicionar';

  @override
  String get commonContinuing => 'Continuando…';

  @override
  String get commonContinue => 'Continuar';

  @override
  String get commonContinueToPlan => 'Continuar para o plano';

  @override
  String get commonPasswordRequired => 'Senha obrigatória';

  @override
  String get commonForgotPassword => 'Esqueci minha senha';

  @override
  String get commonLoggingIn => 'Entrando…';

  @override
  String get commonLogin => 'Entrar';

  @override
  String get commonDash => '—';

  @override
  String get alumnoAreaTitle => 'Área de alumno';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get alumnoPerfilInvalido => 'Perfil inválido.';

  @override
  String get alumnoBuscarInstituciones => 'Buscar instituciones';

  @override
  String get alumnoBuscarInstitucionesSub =>
      'Encontrá instituciones y actividades.';

  @override
  String get alumnoBuscarInstitucionesPlaceholderTitle => 'Búsqueda';

  @override
  String get alumnoBuscarPlaceholderEmpty => 'No hay resultados.';

  @override
  String alumnoBuscarPlaceholderQuery(Object query) {
    return 'Búsqueda: $query';
  }

  @override
  String get alumnoDashboardTitle => 'Inicio';

  @override
  String get alumnoDashboardMiDni => 'Mi DNI';

  @override
  String get alumnoDashboardMisSolicitudes => 'Mis solicitudes';

  @override
  String get alumnoDashboardMisSolicitudesSub =>
      'Ver el estado de tus solicitudes';

  @override
  String get alumnoDashboardBuscarInstituciones => 'Buscar instituciones';

  @override
  String get alumnoDashboardBuscarInstitucionesSub =>
      'Encontrá instituciones y actividades';

  @override
  String get alumnoDashboardCerrarSesionSub => 'Cerrar tu sesión actual';

  @override
  String get alumnoMisSolicitudesTitle => 'Mis solicitudes';

  @override
  String get alumnoBuscarInstitucionesTitle => 'Buscar instituciones';

  @override
  String get alumnoBuscarPlaceholderTitle => 'Buscar';

  @override
  String get alumnoMenuTitle => 'Menú';

  @override
  String get alumnoMenuHeader => 'ATENA';

  @override
  String get alumnoMenuBody => 'Elegí una opción para continuar.';

  @override
  String get alumnoMenuCtaLogin => 'Ingresar';

  @override
  String get alumnoFechaNacimientoNoFutura =>
      'La fecha de nacimiento no puede ser futura.';

  @override
  String get alumnoSeleccionaFechaNacimiento =>
      'Seleccioná tu fecha de nacimiento.';

  @override
  String get alumnoNoSePudoCrearPerfilPerfilIdVacio =>
      'No se pudo crear el perfil: perfilId vacío.';

  @override
  String get alumnoPerfilRegistroTitle => 'Registro de alumno';

  @override
  String get alumnoDocumentoDniLabel => 'DNI';

  @override
  String get alumnoIngresaDni => 'Ingresá tu DNI.';

  @override
  String get alumnoDniInvalidoRango => 'DNI inválido (rango).';

  @override
  String get alumnoFechaNacimientoPrefix => 'Fecha de nacimiento';

  @override
  String get alumnoBuscarExtracurricularesTitle => 'Buscar extracurriculares';

  @override
  String get alumnoBuscarExtracurricularesHint =>
      'Buscar actividad, institución o grupo…';

  @override
  String get alumnoBuscarExtracurricularesBloqueOpcional => 'Bloque (opcional)';

  @override
  String get alumnoBuscarExtracurricularesEmpty =>
      'No hay extracurriculares disponibles.';

  @override
  String alumnoBuscarExtracurricularesGruposConCupo(Object count) {
    return 'Grupos con cupo: $count';
  }

  @override
  String alumnoBuscarExtracurricularesErrorCargar(Object error) {
    return 'Error al cargar extracurriculares: $error';
  }

  @override
  String alumnoBuscarInstitucionesErrorCargar(Object error) {
    return 'Error al cargar instituciones: $error';
  }

  @override
  String alumnoBuscarInstitucionesErrorCargarMas(Object error) {
    return 'Error al cargar más: $error';
  }

  @override
  String get alumnoBuscarInstitucionesExtraEnConstruccion =>
      'Extracurriculares (en construcción)';

  @override
  String get alumnoBuscarInstitucionesExtraAll => 'Todos';

  @override
  String alumnoBuscarInstitucionesExtraSelected(Object value) {
    return 'Seleccionado: $value';
  }

  @override
  String get alumnoBuscarInstitucionesFiltroExtraTitle =>
      'Filtro extracurricular';

  @override
  String get alumnoBuscarInstitucionesNoHayInstituciones =>
      'No hay instituciones registradas.';

  @override
  String get alumnoBuscarInstitucionesNoResultadosConFiltro =>
      'No hay resultados para este filtro.';

  @override
  String get alumnoBuscarInstitucionesCurricularDisponible =>
      'Curricular disponible';

  @override
  String get alumnoBuscarInstitucionesCurricularNoDisponible =>
      'Curricular no disponible';

  @override
  String get alumnoBuscarInstitucionesExtraSinModulos =>
      'Sin módulos extracurriculares';

  @override
  String alumnoBuscarInstitucionesExtraConModulos(Object count) {
    return 'Módulos: $count';
  }

  @override
  String get alumnoBuscarInstitucionesExtraNoDisponible =>
      'Extracurricular no disponible';

  @override
  String get alumnoBuscarInstitucionesBtnCurricular => 'Curricular';

  @override
  String get alumnoBuscarInstitucionesBtnExtracurricular => 'Extracurricular';

  @override
  String get alumnoCalendarioEspecialInicioClases => 'Inicio de clases';

  @override
  String get alumnoCalendarioEspecialFinClases => 'Fin de clases';

  @override
  String get alumnoCalendarioEspecialReceso => 'Receso';

  @override
  String get alumnoCalendarioEspecialInicioCiclo => 'Inicio de ciclo';

  @override
  String get alumnoCalendarioEspecialFinCiclo => 'Fin de ciclo';

  @override
  String get alumnoCalendarioSnackNoDeclinar =>
      'No se puede declinar este evento.';

  @override
  String get alumnoCalendarioSnackAsistenciaConfirmada =>
      'Asistencia confirmada.';

  @override
  String get alumnoCalendarioSnackAsistenciaQuizas => 'Asistencia: quizás.';

  @override
  String get alumnoCalendarioSnackAsistenciaDeclinada =>
      'Asistencia declinada.';

  @override
  String alumnoCalendarioSnackNoGuardarRsvp(Object error) {
    return 'No se pudo guardar asistencia: $error';
  }

  @override
  String alumnoCalendarioSnackNoGuardarNota(Object error) {
    return 'No se pudo guardar nota: $error';
  }

  @override
  String alumnoCalendarioSnackNoActualizarNota(Object error) {
    return 'No se pudo actualizar nota: $error';
  }

  @override
  String get alumnoCalendarioEliminarConfirm => '¿Querés eliminar este evento?';

  @override
  String alumnoCalendarioSnackNoEliminarNota(Object error) {
    return 'No se pudo eliminar nota: $error';
  }

  @override
  String get alumnoCalendarioNoRequiereAsistencia =>
      'Este evento no requiere asistencia.';

  @override
  String get alumnoCalendarioNotaCanonica => 'Nota canónica';

  @override
  String get alumnoCalendarioTitle => 'Calendario';

  @override
  String get alumnoCalendarioFabNotaAlarma => 'Nota / Alarma';

  @override
  String get alumnoCalendarioNoEventosDia => 'No hay eventos para este día.';

  @override
  String get alumnoCalendarioConfirmarAsistencia => 'Confirmar asistencia';

  @override
  String get alumnoCalendarioDialogNotaAlarma => 'Nota y alarma';

  @override
  String get alumnoCalendarioDialogIngresarTitulo => 'Ingresá un título';

  @override
  String get alumnoCalendarioDialogAlarmaLocal => 'Alarma local';

  @override
  String get alumnoCalendarioDialogAlarmaLocalDesc =>
      'Se guardará solo en este dispositivo.';

  @override
  String get alumnoCalendarioDialogAvisoNotificacion => 'Aviso: notificación';

  @override
  String get alumnoNotificacionesDeleteOneTitle => 'Eliminar notificación';

  @override
  String get alumnoNotificacionesDeleteOneBody =>
      '¿Querés eliminar esta notificación?';

  @override
  String get alumnoNotificacionesDeleteAllTitle => 'Eliminar todas';

  @override
  String get alumnoNotificacionesDeleteAllBody =>
      '¿Querés eliminar todas las notificaciones?';

  @override
  String get alumnoNotificacionesDeleteAllCta => 'Eliminar todas';

  @override
  String get alumnoNotificacionesDeleteAllFailed => 'No se pudo eliminar todo.';

  @override
  String get alumnoNotificacionesActionOpenDocumentos => 'Abrir Documentación';

  @override
  String get alumnoNotificacionesActionOpenCalendario => 'Abrir Calendario';

  @override
  String get alumnoNotificacionesActionOpenBoletines => 'Abrir Boletines';

  @override
  String get alumnoNotificacionesActionOpenBecas => 'Abrir Becas';

  @override
  String get alumnoNotificacionesActionOpenConvivencia => 'Abrir Convivencia';

  @override
  String get alumnoNotificacionesActionOpenEquivalencias =>
      'Abrir Equivalencias';

  @override
  String get alumnoNotificacionesActionViewDetail => 'Ver detalle';

  @override
  String get alumnoNotificacionesSectionNotReady =>
      'Sección no disponible todavía.';

  @override
  String alumnoNotificacionesDialogActionLine(Object value) {
    return 'Acción: $value';
  }

  @override
  String alumnoNotificacionesDialogProfileLine(Object value) {
    return 'Perfil: $value';
  }

  @override
  String alumnoNotificacionesDialogDateLine(Object value) {
    return 'Fecha: $value';
  }

  @override
  String alumnoNotificacionesDialogDeeplinkLine(Object value) {
    return 'Deeplink: $value';
  }

  @override
  String get alumnoNotificacionesTitle => 'Notificaciones';

  @override
  String alumnoNotificacionesTitleWithUnread(Object count) {
    return 'Notificaciones ($count sin leer)';
  }

  @override
  String get alumnoNotificacionesDeleteAllTooltip => 'Eliminar todas';

  @override
  String get alumnoNotificacionesNoOwnerBody =>
      'Se requiere sesión activa para ver notificaciones.';

  @override
  String get alumnoNotificacionesEmptyTitle => 'Sin notificaciones';

  @override
  String get alumnoNotificacionesEmptyBody =>
      'No hay notificaciones disponibles.';

  @override
  String get alumnoNotificacionesMarkRead => 'Marcar como leída';

  @override
  String get alumnoNotificacionesMarkUnread => 'Marcar como no leída';

  @override
  String get alumnoNotificacionesFilterStatusLabel => 'Estado';

  @override
  String get alumnoNotificacionesFilterTypeLabel => 'Tipo';

  @override
  String alumnoNotificacionesShowingCount(Object count) {
    return 'Mostrando: $count';
  }

  @override
  String alumnoNotificacionesShowingCountWithPerfil(
    Object count,
    Object perfil,
  ) {
    return 'Mostrando: $count · Perfil: $perfil';
  }

  @override
  String get alumnoPdfsInvalidPerfil => 'Perfil inválido.';

  @override
  String alumnoPdfsSavedPath(Object path) {
    return 'Guardado en: $path';
  }

  @override
  String get alumnoPdfsTitle => 'PDFs';

  @override
  String get alumnoPdfsFichaTitle => 'Ficha';

  @override
  String alumnoPdfsPerfilId(Object perfilId) {
    return 'Perfil: $perfilId';
  }

  @override
  String get alumnoPdfsCroquisTitle => 'Croquis';

  @override
  String get alumnoPdfsCroquisPlaceholder => 'Croquis no disponible.';

  @override
  String get alumnoSeleccionGrupoInstitutionLoadFailed =>
      'No se pudo cargar la institución.';

  @override
  String alumnoSeleccionGrupoLoadError(Object error) {
    return 'Error al cargar: $error';
  }

  @override
  String alumnoSeleccionGrupoExtraLoadError(Object error) {
    return 'Error al cargar extracurriculares: $error';
  }

  @override
  String get alumnoSeleccionGrupoPickCourseAndShift =>
      'Elegí curso/grupo y turno.';

  @override
  String get alumnoSeleccionGrupoPickExtraActivity =>
      'Elegí una actividad extracurricular.';

  @override
  String get alumnoSeleccionGrupoExtraNoSlots => 'No hay cupos disponibles.';

  @override
  String get alumnoSeleccionGrupoNoSlotsShort => 'Sin cupos';

  @override
  String get alumnoSeleccionGrupoNoSlots => 'No hay cupos disponibles.';

  @override
  String get alumnoSeleccionGrupoExtraFilterByBlock => 'Filtrar por bloque';

  @override
  String get alumnoSeleccionGrupoExtraEmpty =>
      'No hay resultados para este filtro.';

  @override
  String get alumnoSeleccionGrupoModeCurricular => 'Curricular';

  @override
  String get alumnoSeleccionGrupoModeExtracurricular => 'Extracurricular';

  @override
  String alumnoSeleccionGrupoTitle(Object mode) {
    return 'Seleccionar grupo – $mode';
  }

  @override
  String get alumnoSeleccionGrupoExtraRefresh => 'Actualizar';

  @override
  String get alumnoSeleccionGrupoCtaCurricular => 'Continuar (curricular)';

  @override
  String get alumnoSeleccionGrupoCtaExtracurricular =>
      'Continuar (extracurricular)';

  @override
  String get alumnoSolicitarVacanteMissingOwnerPerfil =>
      'Falta contexto de sesión (owner/perfil).';

  @override
  String get alumnoSolicitarVacanteInvalidInstitution =>
      'Institución inválida.';

  @override
  String get alumnoSolicitarVacanteInvalidActivity => 'Actividad inválida.';

  @override
  String get alumnoSolicitarVacanteCurricularRequiresAula =>
      'Curricular requiere aula/grupo.';

  @override
  String get alumnoSolicitarVacanteConfirmTitle => 'Confirmar solicitud';

  @override
  String get alumnoSolicitarVacanteTypeCurricular => 'Curricular';

  @override
  String get alumnoSolicitarVacanteTypeExtracurricular => 'Extracurricular';

  @override
  String get alumnoSolicitarVacanteTitle => 'Solicitar vacante';

  @override
  String alumnoSolicitarVacanteSummarySemantics(Object value) {
    return 'Resumen: $value';
  }

  @override
  String get alumnoSolicitarVacanteSendCta => 'Enviar solicitud';

  @override
  String get institucionLoginBadCredentials => 'Credenciales incorrectas.';

  @override
  String get institucionLoginInvalidInstitutionId =>
      'ID de institución inválido.';

  @override
  String get institucionLoginTitle => 'Ingresar';

  @override
  String get institucionLoginAppBar => 'Acceso de institución';

  @override
  String get institucionRegistroPickAtLeastOneModule =>
      'Seleccioná al menos un módulo.';

  @override
  String get institucionRegistroAppBar => 'Registro de institución';

  @override
  String get institucionRegistroIntro =>
      'Completá los datos para registrar la institución.';

  @override
  String get institucionRegistroSectionBasics => 'Datos básicos';

  @override
  String get institucionRegistroInstitutionName => 'Nombre de la institución';

  @override
  String get institucionRegistroCuit => 'CUIT';

  @override
  String get institucionRegistroCuitInvalid => 'CUIT inválido.';

  @override
  String get institucionRegistroAddress => 'Dirección';

  @override
  String get institucionRegistroSectionLocation => 'Ubicación';

  @override
  String get institucionRegistroCountry => 'País';

  @override
  String get institucionRegistroProvince => 'Provincia';

  @override
  String get institucionRegistroCity => 'Ciudad';

  @override
  String get institucionRegistroSectionAccessContact => 'Acceso y contacto';

  @override
  String get institucionRegistroSectionConfig => 'Configuración';

  @override
  String get institucionRegistroInstitutionType => 'Tipo de institución';

  @override
  String get institucionRegistroModality => 'Modalidad';

  @override
  String get institucionRegistroSectionModules => 'Módulos';

  @override
  String get institucionRegistroCurricularSubtitle =>
      'Seleccioná niveles curriculares';

  @override
  String institucionRegistroCurricularChipSemantics(Object value) {
    return 'Nivel curricular: $value';
  }

  @override
  String get institucionRegistroExtracurricularSubtitle =>
      'Seleccioná bloques extracurriculares';

  @override
  String institucionRegistroExtracurricularChipSemantics(Object value) {
    return 'Bloque extracurricular: $value';
  }

  @override
  String get cuentaHomeDeeplinkOwnerMismatch =>
      'Este deeplink pertenece a otra cuenta.';

  @override
  String get cuentaHomeDeeplinkAlumnoRequired =>
      'Se requiere un perfil de alumno para este deeplink.';

  @override
  String get cuentaHomeDestinoCalendario => 'Calendario';

  @override
  String get cuentaHomeDestinoDocumentos => 'Documentación';

  @override
  String cuentaHomeDeeplinkMissingPerfilId(Object path) {
    return 'Falta perfilId para abrir este deeplink: $path';
  }

  @override
  String get cuentaHomeCrearInstitucionTitle => 'Crear institución';

  @override
  String get cuentaHomeCrearInstitucionNombreLabel => 'Nombre';

  @override
  String get cuentaHomeCrearInstitucionNombreRequired => 'Ingresá el nombre.';

  @override
  String get cuentaHomeCrearInstitucionEmailLabel => 'Email';

  @override
  String get cuentaHomeCrearInstitucionEmailRequired => 'Ingresá el email.';

  @override
  String get cuentaHomeCrearInstitucionTelefonoLabel => 'Teléfono';

  @override
  String get cuentaHomeCrearInstitucionTelefonoRequired =>
      'Ingresá el teléfono.';

  @override
  String get cuentaHomeCrearPerfilTitle => 'Crear perfil';

  @override
  String get cuentaHomeTipoAlumno => 'Alumno';

  @override
  String get cuentaHomeTipoInstitucion => 'Institución';

  @override
  String get cuentaHomeContinuarUltimoPerfil =>
      'Continuar con el último perfil';

  @override
  String get cuentaHomeTitle => 'Cuenta';

  @override
  String get cuentaHomeRedirectingInstitution => 'Redirigiendo a institución…';

  @override
  String get cuentaHomePreparingInstitution => 'Preparando institución…';

  @override
  String get cuentaHomeCreateProfileCta => 'Crear perfil';

  @override
  String cuentaHomeAccountLine(Object ownerId) {
    return 'Cuenta: $ownerId';
  }

  @override
  String get cuentaHomeNoProfiles => 'Todavía no hay perfiles.';

  @override
  String get cuentaHomeInstitutionsSection => 'Instituciones';

  @override
  String cuentaHomeInstitutionIdLine(Object id) {
    return 'Institución: $id';
  }

  @override
  String get cuentaHomeStudentsSection => 'Alumnos';

  @override
  String get cuentaHomeNoStudents => 'Todavía no hay alumnos.';

  @override
  String cuentaHomeStudentDniLine(Object dni) {
    return 'DNI: $dni';
  }

  @override
  String get commonPreview => 'Vista previa';

  @override
  String get alumnoBuscarInstitucionesHint => 'Buscar institución o actividad…';

  @override
  String get commonMon => 'Lun';

  @override
  String get commonTue => 'Mar';

  @override
  String get commonWed => 'Mié';

  @override
  String get commonThu => 'Jue';

  @override
  String get commonFri => 'Vie';

  @override
  String get commonSat => 'Sáb';

  @override
  String get commonSun => 'Dom';

  @override
  String get commonInvalidSession => 'Sesión inválida.';

  @override
  String get commonUnread => 'No leída';

  @override
  String get commonRead => 'Leída';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get commonShiftMorning => 'Mañana';

  @override
  String get commonShiftAfternoon => 'Tarde';

  @override
  String get commonShiftNight => 'Noche';

  @override
  String alumnoSeleccionGrupoOpenSolicitudError(Object error) {
    return 'No se pudo abrir Solicitudes: $error';
  }

  @override
  String alumnoSeleccionGrupoSlotsAvailable(Object count) {
    return 'Cupos disponibles: $count';
  }

  @override
  String get institucionAreaSemanticsCroquisLocked => 'Croqui indisponível';

  @override
  String get institucionPlanBillingTitle => 'Facturación y cobro';

  @override
  String get institucionPlanBillingSubtitle =>
      'Cómo funciona el cobro en ATENA (fase 2)';

  @override
  String get institucionPlanBillingIntro =>
      'Antes de confirmar, tené en cuenta lo siguiente:';

  @override
  String get institucionPlanBillingPoint1 =>
      'ATENA solo cobra a instituciones (no a alumnos).';

  @override
  String get institucionPlanBillingPoint2 =>
      'En fase 2 no hay cobros reales: la confirmación es local/prototipo.';

  @override
  String get institucionPlanBillingPoint3 =>
      'El plan habilita niveles y módulos; podés cambiarlo más adelante.';

  @override
  String get institucionPlanBillingPoint4 =>
      'Las instituciones pueden administrar sus perfiles de trabajo por actividad sin compartir credenciales.';

  @override
  String get institucionPlanBillingPoint5 =>
      'Cuando integremos pagos reales, se aplicarán términos, facturación y políticas de reembolso según la configuración final.';

  @override
  String institutionProfileTitle(Object name) {
    return 'Perfil de institución – $name';
  }

  @override
  String institutionProfileLoadError(Object error) {
    return 'No se pudo cargar el perfil: $error';
  }

  @override
  String institutionProfileSaveError(Object error) {
    return 'No se pudo guardar el perfil: $error';
  }

  @override
  String get institutionProfileSectionIdentity => 'Identidad';

  @override
  String get institutionProfileSectionContact => 'Contacto';

  @override
  String get institutionProfileSectionLocation => 'Ubicación';

  @override
  String get institutionProfileSectionSettings => 'Configuración';

  @override
  String get institutionProfileFieldName => 'Nombre';

  @override
  String get institutionProfileFieldCuit => 'CUIT';

  @override
  String get institutionProfileFieldEmail => 'Email';

  @override
  String get institutionProfileFieldPhone => 'Teléfono';

  @override
  String get institutionProfileFieldAddress => 'Dirección';

  @override
  String get institutionProfileFieldCountry => 'País';

  @override
  String get institutionProfileFieldProvince => 'Provincia';

  @override
  String get institutionProfileFieldCity => 'Ciudad';

  @override
  String get institutionProfileFieldModalidad => 'Modalidad';

  @override
  String get institutionProfileFieldType => 'Tipo de institución';

  @override
  String get institutionProfileFieldCurricular => 'Curricular';

  @override
  String get institutionProfileFieldExtracurricular => 'Extracurricular';

  @override
  String institutionProfileModalidadLabel(Object key) {
    return '$key';
  }

  @override
  String institutionProfileTipoLabel(Object key) {
    return '$key';
  }

  @override
  String get commonFixErrors => 'Corregí los errores del formulario.';

  @override
  String get commonRequiredField => 'Campo obligatorio.';

  @override
  String get commonSaved => 'Guardado.';

  @override
  String get saved => 'Guardado.';

  @override
  String get primeroSeleccionaUnaActividad =>
      'Primero seleccioná una actividad';

  @override
  String get losPerfilesDeTrabajoSonInternos =>
      'Los perfiles de trabajo son internos';

  @override
  String get perfilesDeTrabajo => 'Perfiles de trabajo';

  @override
  String get entrar => 'Entrar';

  @override
  String get bloqueadoPorVos => 'Bloqueado por vos';

  @override
  String get bloqueado => 'Bloqueado';

  @override
  String bloqueadoPor(Object who) {
    return 'Bloqueado por $who';
  }

  @override
  String get seleccionarActividad => 'Seleccionar actividad';

  @override
  String get noHayActividadesHabilitadas =>
      'Todavía no hay actividades configuradas';

  @override
  String institutionPublicProfileTitle(Object name) {
    return 'Perfil público – $name';
  }

  @override
  String get institutionPublicProfileSectionOverview => 'Presentación';

  @override
  String get institutionPublicProfileSectionServices => 'Servicios';

  @override
  String get institutionPublicProfileSectionCourses => 'Cursos';

  @override
  String get institutionPublicProfileSectionAdminHours =>
      'Horarios de atención';

  @override
  String get institutionPublicProfileSectionOnline => 'Web y redes';

  @override
  String get institutionPublicProfileSectionPhotos => 'Fotos';

  @override
  String get institutionPublicProfileAboutLabel => 'Descripción';

  @override
  String get institutionPublicProfileAboutHint =>
      'Contá brevemente qué ofrece la institución (máx. 500 caracteres).';

  @override
  String get institutionPublicProfileServicesLabel => 'Servicios';

  @override
  String get institutionPublicProfileServicesHint =>
      'ej.: apoyo escolar, talleres, comedor, transporte…';

  @override
  String get institutionPublicProfileAddService => 'Agregar servicio';

  @override
  String get institutionPublicProfileServiceNameLabel => 'Servicio';

  @override
  String get institutionPublicProfileServiceNameHint => 'ej.: Apoyo escolar';

  @override
  String get institutionPublicProfileServiceInvalid => 'Servicio inválido.';

  @override
  String get institutionPublicProfileShortCoursesLabel =>
      'Ofrece cursos cortos';

  @override
  String get institutionPublicProfileCourseDurationLabel =>
      'Duración (opcional)';

  @override
  String get institutionPublicProfileCourseDurationHint =>
      'ej.: 4 semanas / 2 meses';

  @override
  String get institutionPublicProfileCourseDurationInvalid =>
      'Duración inválida.';

  @override
  String get institutionPublicProfileTeachingModeLabel => 'Tipo de cursado';

  @override
  String get institutionPublicProfileTeachingModePresencial => 'Presencial';

  @override
  String get institutionPublicProfileTeachingModeRemoto => 'A distancia';

  @override
  String get institutionPublicProfileTeachingModeHibrido => 'Híbrido';

  @override
  String get institutionPublicProfileAdminHoursLabel =>
      'Horario de atención administrativa';

  @override
  String get institutionPublicProfileAdminHoursHint =>
      'ej.: Lun a Vie 9:00 a 17:00';

  @override
  String get institutionPublicProfilePhoneOptionalLabel =>
      'Teléfono (opcional)';

  @override
  String get institutionPublicProfileWebsiteLabel => 'Página web (opcional)';

  @override
  String get institutionPublicProfileWebsiteHint => 'https://…';

  @override
  String get institutionPublicProfileWebsiteInvalid => 'URL inválida.';

  @override
  String get institutionPublicProfileInstagramLabel => 'Instagram (opcional)';

  @override
  String get institutionPublicProfileFacebookLabel => 'Facebook (opcional)';

  @override
  String get institutionPublicProfileXLabel => 'X / Twitter (opcional)';

  @override
  String get institutionPublicProfileYoutubeLabel => 'YouTube (opcional)';

  @override
  String get institutionPublicProfileTiktokLabel => 'TikTok (opcional)';

  @override
  String get institutionPublicProfileLinkedinLabel => 'LinkedIn (opcional)';

  @override
  String get institutionPublicProfileOtherLinkLabel => 'Otro link (opcional)';

  @override
  String get institutionPublicProfilePricesLabel => 'Precios (opcional)';

  @override
  String get institutionPublicProfilePricesHint =>
      'ej.: desde \$… / rango / consultar';

  @override
  String get institutionPublicProfilePricesTooLong => 'Texto demasiado largo.';

  @override
  String institutionPublicProfilePhotosLabel(Object max) {
    return 'Galería (hasta $max)';
  }

  @override
  String get institutionPublicProfileAddPhoto => 'Agregar foto';

  @override
  String get institutionPublicProfileChangePhoto => 'Cambiar foto';

  @override
  String get institutionPublicProfileRemovePhoto => 'Eliminar foto';

  @override
  String institutionPublicProfilePhotoLimitReached(Object max) {
    return 'Ya cargaste el máximo de fotos ($max).';
  }

  @override
  String get institutionPublicProfileNoPhotosYet => 'Todavía no hay fotos.';

  @override
  String institutionPublicProfilePickPhotoError(Object error) {
    return 'No se pudo cargar la foto: $error';
  }

  @override
  String get institutionPublicProfileSaveOk => 'Perfil guardado.';

  @override
  String institutionPublicProfileSaveFailed(Object error) {
    return 'No se pudo guardar el perfil: $error';
  }

  @override
  String get institucionGeneric => 'Instituição';

  @override
  String get institucionExtracBaseEmitirFichaTitle => 'Emitir ficha';

  @override
  String institucionExtracBaseEmitirFichaSubtitle(Object group) {
    return 'Emitir ficha como notificação';
  }

  @override
  String get institucionExtracBaseEmitirFichaGrupoLabel => 'Grupo';

  @override
  String get institucionExtracBaseEmitirFichaTituloLabel => 'Título';

  @override
  String get institucionExtracBaseEmitirFichaTituloHint =>
      'ej.: Reunión informativa';

  @override
  String get institucionExtracBaseEmitirFichaContenidoLabel => 'Contenido';

  @override
  String get institucionExtracBaseEmitirFichaContenidoHint =>
      'Escribí el detalle de la ficha…';

  @override
  String get institucionExtracBaseEmitirFichaAddToCalendar =>
      'Agregar al calendario';

  @override
  String get institucionExtracBaseEmitirFichaAddToCalendarHelp =>
      'Si está activado, se crea un evento en el calendario del alumno.';

  @override
  String get institucionExtracBaseEmitirFichaRequireRsvp =>
      'Requiere confirmación';

  @override
  String get institucionExtracBaseEmitirFichaRequireRsvpHelp =>
      'Si está activado, el alumno podrá confirmar asistencia (sí / quizás / no).';

  @override
  String get institucionExtracBaseEmitirFichaDestinatariosTitle =>
      'Destinatarios';

  @override
  String get institucionExtracBaseEmitirFichaDestinatariosEmptyHelp =>
      'No hay destinatarios disponibles para este grupo.';

  @override
  String get institucionExtracBaseEmitirFichaManualLabel =>
      'Destinatarios manuales';

  @override
  String get institucionExtracBaseEmitirFichaManualHint =>
      'Ingresá uno o más documentos/IDs, separados por coma';

  @override
  String get actionSelectAll => 'Selecionar tudo';

  @override
  String get actionSelectNone => 'Selecionar nenhum';

  @override
  String get actionEmit => 'Emitir';

  @override
  String institucionExtracBaseEmitirFichaDefaultTitle(Object module) {
    return 'Ficha';
  }

  @override
  String get institucionExtracBaseEmitirFichaDefaultBody =>
      'Se generó una ficha para compartir información del grupo.';

  @override
  String get institucionExtracBaseEmitirFichaNoRecipients =>
      'No hay destinatarios seleccionados.';

  @override
  String get institucionExtracBaseEmitirFichaOk => 'Ficha emitida.';

  @override
  String get institucionExtracBaseEmitirFichaServiceMissing =>
      'Servicio no disponible.';

  @override
  String institucionExtracBaseEmitirFichaFailed(Object error) {
    return 'Não foi possível emitir a ficha: $error';
  }

  @override
  String get institucionExtracBaseEmitirFichaBanner =>
      'Emití fichas como notificación y, opcionalmente, como evento de calendario.';

  @override
  String get institucionExtracBaseEmitirFichaCardTitle => 'Emitir ficha';

  @override
  String get institucionExtracBaseEmitirFichaCardSubtitle =>
      'Crear una ficha informativa para el grupo seleccionado';

  @override
  String get institucionExtracBaseOpenInboxCta => 'Abrir notificaciones';

  @override
  String get institucionExtracBaseEmitirFichaCardFootnote =>
      'Las fichas se guardan como notificación (prototipo).';

  @override
  String get send => 'Enviar';
}
