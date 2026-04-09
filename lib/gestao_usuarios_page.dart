import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models/usuario_consultor.dart';

const kPrimary = Color(0xFFD32F2F);
const kBaseUrl = 'https://jornadabackend-hr3v.onrender.com';

class GestaoUsuariosPage extends StatefulWidget {
  const GestaoUsuariosPage({super.key});

  @override
  State<GestaoUsuariosPage> createState() => _GestaoUsuariosPageState();
}

class _GestaoUsuariosPageState extends State<GestaoUsuariosPage> {
  List<UsuarioConsultor> _usuarios = [];
  bool _loading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    await _carregarUsuarios();
  }

  Future<void> _carregarUsuarios() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(
        Uri.parse('$kBaseUrl/gestor/usuarios'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _usuarios = (data['usuarios'] as List)
              .map((u) => UsuarioConsultor.fromJson(u))
              .toList();
        });
      } else {
        _showError('Erro ao carregar usuários (${resp.statusCode})');
      }
    } catch (e) {
      _showError('Erro de conexão: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // ── Criar Usuário ─────────────────────────────────────────────────────────
  void _abrirCriarUsuario() {
    final _formKey = GlobalKey<FormState>();
    final _nomeCtrl   = TextEditingController();
    final _emailCtrl  = TextEditingController();
    final _telCtrl    = TextEditingController();
    final _senhaCtrl  = TextEditingController();
    String _cargo     = 'consultor';
    bool _obscure     = true;
    bool _salvando    = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black54));
          final focusBorder = border.copyWith(
              borderSide: const BorderSide(color: kPrimary, width: 2));

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 24, right: 24, top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Alça
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Novo Usuário',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Nome
                    TextFormField(
                      controller: _nomeCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nome completo *',
                        prefixIcon: const Icon(Icons.person, color: kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                    ),
                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: const Icon(Icons.email, color: kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Telefone
                    TextFormField(
                      controller: _telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        prefixIcon: const Icon(Icons.phone, color: kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cargo
                    DropdownButtonFormField<String>(
                      value: _cargo,
                      decoration: InputDecoration(
                        labelText: 'Cargo *',
                        prefixIcon: const Icon(Icons.badge, color: kPrimary),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'consultor',  child: Text('Consultor')),
                        DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                        DropdownMenuItem(value: 'gestor',     child: Text('Gestor')),
                      ],
                      onChanged: (v) => setSheet(() => _cargo = v!),
                    ),
                    const SizedBox(height: 14),

                    // Senha
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Senha *',
                        prefixIcon: const Icon(Icons.lock, color: kPrimary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setSheet(() => _obscure = !_obscure),
                        ),
                        enabledBorder: border, focusedBorder: focusBorder,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Informe a senha';
                        if (v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botão salvar
                    ElevatedButton(
                      onPressed: _salvando ? null : () async {
                        if (!(_formKey.currentState?.validate() ?? false)) return;
                        setSheet(() => _salvando = true);
                        try {
                          final resp = await http.post(
                            Uri.parse('$kBaseUrl/gestor/usuario'),
                            headers: {
                              'Content-Type': 'application/json',
                              if (_token != null) 'Authorization': 'Bearer $_token',
                            },
                            body: jsonEncode({
                              'nome_usuario': _nomeCtrl.text.trim(),
                              'email': _emailCtrl.text.trim(),
                              'telefone': _telCtrl.text.trim(),
                              'cargo': _cargo,
                              'senha': _senhaCtrl.text,
                            }),
                          );
                          if (resp.statusCode == 201) {
                            Navigator.pop(ctx);
                            _showSuccess('Usuário criado com sucesso!');
                            _carregarUsuarios();
                          } else {
                            final data = jsonDecode(resp.body);
                            _showError(data['mensagem'] ?? 'Erro ao criar usuário');
                          }
                        } catch (e) {
                          _showError('Erro de conexão: $e');
                        } finally {
                          setSheet(() => _salvando = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _salvando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Criar Usuário', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Resetar Senha ─────────────────────────────────────────────────────────
  void _abrirResetarSenha(UsuarioConsultor usuario) {
    final _senhaCtrl = TextEditingController();
    bool _obscure   = true;
    bool _salvando  = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) {
          return AlertDialog(
            title: Text('Resetar senha de\n${usuario.nomeUsuario}',
                style: const TextStyle(fontSize: 16)),
            content: TextField(
              controller: _senhaCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Nova senha (mín. 6 caracteres)',
                prefixIcon: const Icon(Icons.lock_reset, color: kPrimary),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setDialog(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: _salvando ? null : () async {
                  final senha = _senhaCtrl.text.trim();
                  if (senha.length < 6) {
                    _showError('Mínimo 6 caracteres');
                    return;
                  }
                  setDialog(() => _salvando = true);
                  try {
                    final resp = await http.put(
                      Uri.parse('$kBaseUrl/gestor/usuario/${usuario.idUsuario}/resetar_senha'),
                      headers: {
                        'Content-Type': 'application/json',
                        if (_token != null) 'Authorization': 'Bearer $_token',
                      },
                      body: jsonEncode({'nova_senha': senha}),
                    );
                    Navigator.pop(ctx);
                    if (resp.statusCode == 200) {
                      _showSuccess('Senha resetada com sucesso!');
                    } else {
                      final data = jsonDecode(resp.body);
                      _showError(data['mensagem'] ?? 'Erro ao resetar senha');
                    }
                  } catch (e) {
                    _showError('Erro de conexão: $e');
                  } finally {
                    setDialog(() => _salvando = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
                child: _salvando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Resetar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Deletar Usuário ───────────────────────────────────────────────────────
  void _confirmarDeletar(UsuarioConsultor usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja deletar o usuário "${usuario.nomeUsuario}"?\n\nEssa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final resp = await http.delete(
                  Uri.parse('$kBaseUrl/gestor/usuario/${usuario.idUsuario}'),
                  headers: {
                    'Content-Type': 'application/json',
                    if (_token != null) 'Authorization': 'Bearer $_token',
                  },
                );
                if (resp.statusCode == 200) {
                  _showSuccess('Usuário deletado');
                  _carregarUsuarios();
                } else {
                  final data = jsonDecode(resp.body);
                  _showError(data['mensagem'] ?? 'Erro ao deletar');
                }
              } catch (e) {
                _showError('Erro de conexão: $e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
  }

  // ── Cores do cargo ────────────────────────────────────────────────────────
  Color _cargoCor(String cargo) {
    switch (cargo) {
      case 'gestor':     return Colors.purple;
      case 'supervisor': return Colors.orange;
      default:           return Colors.blue;
    }
  }

  IconData _cargoIcon(String cargo) {
    switch (cargo) {
      case 'gestor':     return Icons.supervisor_account;
      case 'supervisor': return Icons.manage_accounts;
      default:           return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Gestão de Usuários',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarUsuarios,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kPrimary))
          : _usuarios.isEmpty
              ? _buildVazio()
              : RefreshIndicator(
                  onRefresh: _carregarUsuarios,
                  color: kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _usuarios.length,
                    itemBuilder: (_, i) => _buildCard(_usuarios[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCriarUsuario,
        backgroundColor: kPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo Usuário'),
      ),
    );
  }

  Widget _buildVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Nenhum usuário cadastrado',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _abrirCriarUsuario,
            icon: const Icon(Icons.person_add, color: kPrimary),
            label: const Text('Criar primeiro usuário',
                style: TextStyle(color: kPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(UsuarioConsultor u) {
    final cor = _cargoCor(u.cargo);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.12),
          radius: 24,
          child: Icon(_cargoIcon(u.cargo), color: cor, size: 22),
        ),
        title: Text(
          u.nomeUsuario,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(u.cargo,
                  style: TextStyle(
                      fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
            ),
            if (u.email != null && u.email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(u.email!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (v) {
            if (v == 'resetar') _abrirResetarSenha(u);
            if (v == 'deletar') _confirmarDeletar(u);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'resetar',
              child: Row(children: [
                Icon(Icons.lock_reset, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text('Resetar senha'),
              ]),
            ),
            const PopupMenuItem(
              value: 'deletar',
              child: Row(children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Deletar usuário', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}