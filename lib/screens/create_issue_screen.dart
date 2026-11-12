import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../models/cep_address.dart';
import '../models/issue.dart';
import '../models/request_state.dart';
import '../repositories/issue_repository.dart';
import '../services/api_service.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/app_network_image.dart';
import '../widgets/category_style.dart';
import '../widgets/cep_result_view.dart';
import '../widgets/issue_photo_picker.dart';
import 'pick_location_screen.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _repository = IssueRepository.instance;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  String _category = IssueCategory.accessibility;
  String _severity = IssueSeverity.medium;
  RequestState _cepState = RequestState.initial;
  CepAddress? _cepAddress;
  String _cepError = '';
  String _imageData = '';
  bool _photoError = false;
  LatLng? _pickedLocation;
  bool _openingMap = false;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _cepController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        _photoError = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível carregar a imagem.')),
      );
    }
  }

  Future<void> _lookupCep() async {
    FocusScope.of(context).unfocus();
    setState(() => _cepState = RequestState.loading);
    try {
      final address = await ApiService().buscarCep(_cepController.text);
      if (!mounted) return;
      setState(() {
        _cepAddress = address;
        _cepState = RequestState.success;
        _addressController.text = address.fullAddress;
        _pickedLocation = null; // o endereço mudou: a localização será buscada de novo
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cepError = e.message;
        _cepState = RequestState.error;
      });
    }
  }

  void _syncCepWith(String? postcode) {
    _cepController.text = postcode ?? '';
    _cepState = RequestState.initial;
    _cepAddress = null;
    _cepError = '';
  }

  /// Abre o mapa na rua do CEP/endereço informado para marcar o ponto exato.
  Future<void> _pickOnMap() async {
    FocusScope.of(context).unfocus();
    setState(() => _openingMap = true);

    LatLng? center = _pickedLocation;
    var zoom = 18.0;
    if (center == null && _addressController.text.trim().isNotEmpty) {
      try {
        final place = await RouteService().geocode(
          _addressController.text,
          timeout: const Duration(seconds: 8),
        );
        center = place.location;
        zoom = 17.0;
      } on ApiException {
        center = null; // não achou a rua: o mapa abre no centro da cidade
      }
    }
    if (!mounted) return;
    setState(() => _openingMap = false);

    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => PickLocationScreen(
          center: center,
          selected: _pickedLocation,
          zoom: center == null ? 13.0 : zoom,
        ),
      ),
    );
    if (point == null || !mounted) return;
    setState(() => _pickedLocation = point);

    try {
      final place = await RouteService().reverseGeocode(point);
      if (!mounted) return;
      setState(() {
        _addressController.text = place.address;
        _syncCepWith(place.postcode);
      });
    } on ApiException {
      if (!mounted) return;
      setState(() => _syncCepWith(null));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local marcado! Não foi possível descobrir o endereço, preencha manualmente.'),
        ),
      );
    }
  }

  Future<bool?> _askAboutSimilar(Issue similar) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ocorrência parecida por perto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Já existe uma ocorrência da mesma categoria a menos de 100 m daqui:'),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  AppNetworkImage(url: similar.imageUrl, width: 56, height: 56, radius: 8),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(similar.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${similar.likes} de ${similar.activeRegionalUsers} apoios',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Quer apoiá-la em vez de criar uma nova? Juntos, os apoios chegam mais rápido à meta.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Criar mesmo assim'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Apoiar a existente'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final formIsValid = _formKey.currentState!.validate();
    if (_imageData.isEmpty) setState(() => _photoError = true);
    if (!formIsValid || _imageData.isEmpty) return;

    setState(() => _saving = true);
    try {
      final location = await _repository.resolveLocation(
        _addressController.text,
        picked: _pickedLocation,
      );

      final similar = await _repository.findSimilar(location, _category);
      if (similar != null) {
        if (!mounted) return;
        final supportExisting = await _askAboutSimilar(similar);
        if (!mounted) return;
        if (supportExisting == null) {
          setState(() => _saving = false);
          return;
        }
        if (supportExisting) {
          final updated = await _repository.addSupport(similar);
          if (mounted) Navigator.pop(context, updated);
          return;
        }
      }

      final created = await _repository.create(
        title: _titleController.text,
        description: _descController.text,
        category: _category,
        address: _addressController.text,
        location: location,
        severity: _severity,
        imageData: _imageData,
      );
      if (mounted) Navigator.pop(context, created);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível publicar. Tente novamente.')),
      );
    }
  }

  String? _required(String? value, String message, {int min = 1}) =>
      (value == null || value.trim().length < min) ? message : null;

  @override
  Widget build(BuildContext context) {
    final picked = _pickedLocation;
    return Scaffold(
      appBar: AppBar(title: const Text('Nova ocorrência')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            IssuePhotoPicker(
              imageData: _imageData,
              showError: _photoError,
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
              onRemove: () => setState(() => _imageData = ''),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: appInputDecoration(label: 'Título', icon: Icons.title),
              validator: (v) => _required(v, 'Informe um título (mín. 5 letras).', min: 5),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: appInputDecoration(label: 'Categoria', icon: Icons.category_outlined),
              items: IssueCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 14),
            const Text('Gravidade', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final severity in IssueSeverity.all)
                  ChoiceChip(
                    label: Text(IssueSeverity.label(severity)),
                    selected: _severity == severity,
                    selectedColor: SeverityStyle.soft(severity),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _severity == severity ? SeverityStyle.color(severity) : null,
                    ),
                    onSelected: (_) => setState(() => _severity = severity),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                    decoration: appInputDecoration(label: 'CEP', icon: Icons.pin_drop_outlined),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: _cepState == RequestState.loading ? null : _lookupCep,
                    icon: const Icon(Icons.search, color: Colors.white),
                    tooltip: 'Buscar endereço',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CepResultView(
              state: _cepState,
              address: _cepAddress,
              errorMessage: _cepError,
              onRetry: _lookupCep,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressController,
              decoration: appInputDecoration(label: 'Endereço', icon: Icons.place_outlined),
              validator: (v) => _required(v, 'Informe o endereço.'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openingMap ? null : _pickOnMap,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: Text(
                    _openingMap
                        ? 'Abrindo mapa...'
                        : (picked == null ? 'Marcar no mapa' : 'Alterar local'),
                  ),
                ),
                if (picked != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 18, color: AppColors.success),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text('Local marcado', style: TextStyle(fontSize: 12, color: AppColors.success)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Remover local marcado',
                    onPressed: () => setState(() => _pickedLocation = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 4,
              decoration: appInputDecoration(label: 'Descrição'),
              validator: (v) => _required(v, 'Descreva o problema (mín. 10 letras).', min: 10),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.send, size: 18),
                label: Text(_saving ? 'Publicando...' : 'Publicar ocorrência'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}