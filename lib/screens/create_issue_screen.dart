import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/cep_address.dart';
import '../models/issue.dart';
import '../models/request_state.dart';
import '../repositories/issue_repository.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cep_result_view.dart';
import '../widgets/issue_photo_picker.dart';

class CreateIssueScreen extends StatefulWidget {
  const CreateIssueScreen({super.key});

  @override
  State<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends State<CreateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cepController = TextEditingController();
  final _addressController = TextEditingController();
  final _descController = TextEditingController();

  String _category = IssueCategory.accessibility;
  RequestState _cepState = RequestState.initial;
  CepAddress? _cepAddress;
  String _cepError = '';
  String _imageData = '';
  bool _photoError = false;
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
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cepError = e.message;
        _cepState = RequestState.error;
      });
    }
  }

  Future<void> _save() async {
    final formIsValid = _formKey.currentState!.validate();
    if (_imageData.isEmpty) setState(() => _photoError = true);
    if (!formIsValid || _imageData.isEmpty) return;
    setState(() => _saving = true);
    final created = await IssueRepository.instance.create(
      title: _titleController.text,
      description: _descController.text,
      category: _category,
      address: _addressController.text,
      imageData: _imageData,
    );
    if (mounted) Navigator.pop(context, created);
  }

  String? _required(String? value, String message, {int min = 1}) =>
      (value == null || value.trim().length < min) ? message : null;

  @override
  Widget build(BuildContext context) {
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
              initialValue: _category,
              decoration: appInputDecoration(label: 'Categoria', icon: Icons.category_outlined),
              items: IssueCategory.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) => setState(() => _category = value ?? _category),
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
                IconButton.filled(
                  onPressed: _cepState == RequestState.loading ? null : _lookupCep,
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar endereço',
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