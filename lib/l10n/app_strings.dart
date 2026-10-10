import 'package:flutter/material.dart';

class AppStrings {
  AppStrings._();

  static Locale _locale = const Locale('en');

  static void bindLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();

    if (code == 'fr' || code == 'es' || code == 'pt') {
      _locale = Locale(code);
    } else {
      _locale = const Locale('en');
    }
  }

  static String get _code => _locale.languageCode;

  static String _t({
    required String fr,
    required String en,
    required String es,
    required String pt,
  }) {
    switch (_code) {
      case 'fr':
        return fr;
      case 'es':
        return es;
      case 'pt':
        return pt;
      default:
        return en;
    }
  }

  static String get appTitle => _t(
        fr: 'Avant / Après',
        en: 'Before / After',
        es: 'Antes / Después',
        pt: 'Antes / Depois',
      );

  static String get homeSubtitle => _t(
        fr: 'Comparez vos projets facilement',
        en: 'Compare your projects easily',
        es: 'Compara tus proyectos fácilmente',
        pt: 'Compare seus projetos facilmente',
      );

  static String get inProgress => _t(
        fr: 'Projets en cours',
        en: 'In progress projects',
        es: 'Proyectos en curso',
        pt: 'Projetos em andamento',
      );

  static String get doneProjects => _t(
        fr: 'Mes projets',
        en: 'My projects',
        es: 'Mis proyectos',
        pt: 'Meus projetos',
      );

  static String get newProject => _t(
        fr: 'Nouveau',
        en: 'New',
        es: 'Nuevo',
        pt: 'Novo',
      );

  static String get settings => _t(
        fr: 'Réglages',
        en: 'Settings',
        es: 'Ajustes',
        pt: 'Configurações',
      );

  static String get sort => _t(
      fr: 'Trier',
      en: 'Sort',
      es: 'Ordenar',
      pt: 'Ordenar',
    );
    
  static String get title => _t(
        fr: 'Titre',
        en: 'Title',
        es: 'Título',
        pt: 'Título',
      );

  static String get description => _t(
        fr: 'Description',
        en: 'Description',
        es: 'Descripción',
        pt: 'Descrição',
      );

  static String get before => _t(
        fr: 'Avant',
        en: 'Before',
        es: 'Antes',
        pt: 'Antes',
      );

  static String get during => _t(
        fr: 'Pendant',
        en: 'During',
        es: 'Durante',
        pt: 'Durante',
      );

  static String get after => _t(
        fr: 'Après',
        en: 'After',
        es: 'Después',
        pt: 'Depois',
      );

  static String get note => _t(
        fr: 'Note',
        en: 'Note',
        es: 'Nota',
        pt: 'Nota',
      );

  static String get save => _t(
        fr: 'Enregistrer',
        en: 'Save',
        es: 'Guardar',
        pt: 'Salvar',
      );

  static String get cancel => _t(
        fr: 'Annuler',
        en: 'Cancel',
        es: 'Cancelar',
        pt: 'Cancelar',
      );

  static String get delete => _t(
        fr: 'Supprimer',
        en: 'Delete',
        es: 'Eliminar',
        pt: 'Excluir',
      );

  static String get complete => _t(
        fr: 'Compléter',
        en: 'Complete',
        es: 'Completar',
        pt: 'Completar',
      );

  static String get gallery => _t(
        fr: 'Galerie',
        en: 'Gallery',
        es: 'Galería',
        pt: 'Galeria',
      );

  static String get camera => _t(
        fr: 'Caméra',
        en: 'Camera',
        es: 'Cámara',
        pt: 'Câmera',
      );

  static String get grid => _t(
        fr: 'Grille',
        en: 'Grid',
        es: 'Cuadrícula',
        pt: 'Grade',
      );

  static String get list => _t(
        fr: 'Liste',
        en: 'List',
        es: 'Lista',
        pt: 'Lista',
      );

  static String get favorites => _t(
        fr: 'Favori',
        en: 'Favorite',
        es: 'Favorito',
        pt: 'Favorito',
      );

  static String get removeFavorite => _t(
        fr: 'Retirer favori',
        en: 'Remove favorite',
        es: 'Quitar favorito',
        pt: 'Remover favorito',
      );

  static String get open => _t(
        fr: 'Ouvrir',
        en: 'Open',
        es: 'Abrir',
        pt: 'Abrir',
      );

  static String get palette => _t(
        fr: 'Palette',
        en: 'Palette',
        es: 'Paleta',
        pt: 'Paleta',
      );

  static String get brokenImage => _t(
        fr: 'Image cassée',
        en: 'Broken image',
        es: 'Imagen no disponible',
        pt: 'Imagem indisponível',
      );

  static String get noPhoto => _t(
        fr: 'Aucune photo',
        en: 'No photo',
        es: 'Sin foto',
        pt: 'Sem foto',
      );

  static String get preview => _t(
        fr: 'Aperçu',
        en: 'Preview',
        es: 'Vista previa',
        pt: 'Prévia',
      );

  static String get missingProject => _t(
        fr: 'Projet introuvable',
        en: 'Project not found',
        es: 'Proyecto no encontrado',
        pt: 'Projeto não encontrado',
      );

  static String get noProjects => _t(
        fr: 'Aucun projet pour le moment',
        en: 'No projects yet',
        es: 'Aún no hay proyectos',
        pt: 'Nenhum projeto ainda',
      );

  static String get titleRequired => _t(
        fr: 'Le titre est obligatoire',
        en: 'Title is required',
        es: 'El título es obligatorio',
        pt: 'O título é obrigatório',
      );

  static String get beforeRequired => _t(
        fr: 'La photo Avant est obligatoire',
        en: 'The before photo is required',
        es: 'La foto de antes es obligatoria',
        pt: 'A foto de antes é obrigatória',
      );

  static String get deleteProjectTitle => _t(
        fr: 'Supprimer ce projet ?',
        en: 'Delete this project?',
        es: '¿Eliminar este proyecto?',
        pt: 'Excluir este projeto?',
      );

  static String get deleteProjectMessage => _t(
        fr: 'Voulez-vous supprimer ce projet ?',
        en: 'Do you want to delete this project?',
        es: '¿Quieres eliminar este proyecto?',
        pt: 'Deseja excluir este projeto?',
      );

  static String get addAfterOrDuring => _t(
        fr: 'Ajouter Pendant / Après',
        en: 'Add During / After',
        es: 'Añadir Durante / Después',
        pt: 'Adicionar Durante / Depois',
      );

  static String get language => _t(
        fr: 'Langue',
        en: 'Language',
        es: 'Idioma',
        pt: 'Idioma',
      );

  static String get rateApp => _t(
        fr: 'Noter l’application',
        en: 'Rate the app',
        es: 'Valorar la aplicación',
        pt: 'Avaliar o aplicativo',
      );
}