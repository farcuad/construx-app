import 'app_language.dart';
import 'app_strings.dart';
import 'sections/admin_strings.dart';
import 'sections/common_strings.dart';
import 'sections/finance_strings.dart';
import 'sections/resources_strings.dart';
import 'sections/site_strings.dart';

/// Textos em português.
const AppStrings kStringsPt = AppStrings(
  language: AppLanguage.pt,
  moduleTitles: <String, String>{
    'projects': 'Obras',
    'clients': 'Clientes',
    'budgets': 'Orçamentos',
    'expenses': 'Despesas',
    'purchases': 'Ordens de compra',
    'suppliers': 'Fornecedores',
    'inventory': 'Estoque',
    'equipment': 'Maquinário',
    'personnel': 'Pessoal',
    'attendance': 'Presença',
    'contractors': 'Empreiteiros',
    'schedule': 'Cronograma',
    'progress': 'Andamento da obra',
    'photos': 'Fotos',
    'invoices': 'Faturamento',
    'documents': 'Documentos',
    'users': 'Usuários',
    'audits': 'Auditoria',
  },
  panel: 'Painel',
  brandSubtitle: 'GESTÃO DE OBRA',
  openMenu: 'Abrir menu',
  refresh: 'Atualizar',
  retry: 'Tentar de novo',
  somethingWentWrong: 'Algo deu errado',
  cancel: 'Cancelar',
  close: 'Fechar',
  unknownName: 'Sem nome',
  noRole: 'Sem cargo',
  notices: 'Avisos',
  noticesEmptyTitle: 'Tudo tranquilo',
  noticesEmptyMessage: 'Você não tem avisos pendentes.',
  noticesError: 'Não foi possível carregar os avisos.',
  noticeMarkedRead: 'Aviso marcado como lido',
  unreadOne: '1 aviso não lido',
  unreadMany: '{n} avisos não lidos',
  noticeChannelName: 'Avisos de obra',
  noticeChannelDescription:
      'Novidades dos seus projetos: orçamentos, tarefas e ocorrências.',
  offlineTitle: 'Sem conexão',
  offlineMessage:
      'O Construx precisa de internet para funcionar. Verifique o wi-fi ou os '
      'dados móveis: assim que o sinal voltar, você continua de onde parou.',
  offlineRestored: 'Conexão restabelecida',
  settings: 'Ajustes',
  settingsSession: 'Sessão',
  settingsPreferences: 'Preferências',
  settingsLegal: 'Jurídico',
  languageLabel: 'Idioma',
  languagePickerTitle: 'Escolha um idioma',
  terms: 'Termos e condições',
  termsIntro:
      'Resumo das condições de uso do Construx dentro da sua empresa. '
      'Prevalece sempre o contrato assinado entre a sua empresa e o fornecedor '
      'do serviço.',
  termsSections: <TermsSection>[
    (
      title: 'Uso do aplicativo',
      body:
          'O Construx é uma ferramenta de trabalho. Só podem usá-lo as '
          'pessoas a quem a empresa deu credenciais, e apenas para a gestão '
          'das obras dessa empresa.',
    ),
    (
      title: 'Sua conta',
      body:
          'As credenciais são pessoais e intransferíveis. Tudo o que for feito '
          'a partir da sua conta fica registrado em seu nome na auditoria do '
          'sistema. Se achar que outra pessoa tem acesso, avise imediatamente '
          'o administrador da sua empresa.',
    ),
    (
      title: 'Dados que você registra',
      body:
          'As despesas, relatórios de andamento, fotografias e demais '
          'informações que você insere pertencem à sua empresa, responsável '
          'por esses dados. Ficam guardados nos servidores dela enquanto '
          'durar a relação contratual.',
    ),
    (
      title: 'Fotografias da obra',
      body:
          'As fotos enviadas são documentação da obra: podem ser usadas como '
          'prova de andamento, em relatórios e perante clientes. Evite '
          'capturar pessoas ou documentos alheios ao trabalho.',
    ),
    (
      title: 'Disponibilidade',
      body:
          'O serviço pode ser interrompido por manutenção ou por causas alheias '
          'ao fornecedor. Sua empresa pode revogar o seu acesso a qualquer '
          'momento, por exemplo ao encerrar o vínculo de trabalho.',
    ),
  ],
  logout: 'Sair da conta',
  logoutMessage: 'Deseja mesmo sair? Os dados lembrados são mantidos.',
  logoutConfirm: 'Sair',
  version: 'Versão',
  common: kCommonPt,
  budgets: kBudgetsPt,
  expenses: kExpensesPt,
  purchases: kPurchasesPt,
  suppliers: kSuppliersPt,
  invoices: kInvoicesPt,
  schedule: kSchedulePt,
  progress: kProgressPt,
  attendance: kAttendancePt,
  photos: kPhotosPt,
  contractors: kContractorsPt,
  day: kDayPt,
  inventory: kInventoryPt,
  equipment: kEquipmentPt,
  personnel: kPersonnelPt,
  documents: kDocumentsPt,
  projects: kProjectsPt,
  clients: kClientsPt,
  users: kUsersPt,
  audits: kAuditsPt,
  projectScope: kProjectScopePt,
  dashboard: kDashboardPt,
  auth: kAuthPt,
);
