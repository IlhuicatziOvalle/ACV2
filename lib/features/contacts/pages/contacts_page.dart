import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:alerta_acv/services/device/floating_911_button.dart';
import 'package:alerta_acv/models/emergency_contact.dart';
import 'package:alerta_acv/services/database_service.dart';
import 'package:alerta_acv/services/phone_utils.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _db = DatabaseService.instance;
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final items = await _db.getAllContacts();
    if (!mounted) return;
    setState(() {
      _contacts = items;
      _loading = false;
    });
  }

  Future<void> _addOrEditContact({EmergencyContact? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phoneNumber ?? '');

    final result = await showDialog<EmergencyContact?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(existing == null ? 'Agregar contacto' : 'Editar contacto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nombre y teléfono son requeridos')),
                  );
                  return;
                }
                final contact = EmergencyContact(
                  id: existing?.id,
                  name: name,
                  phoneNumber: phone,
                );
                Navigator.of(ctx).pop(contact);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    if (existing == null) {
      await _db.createContact(result);
    } else {
      await _db.updateContact(result);
    }
    await _loadContacts();
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: Text('¿Eliminar a ${contact.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok == true) {
      if (contact.id != null) {
        await _db.deleteContact(contact.id!);
        await _loadContacts();
      }
    }
  }

  Future<void> _importFromDeviceContacts() async {
    try {
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de contactos denegado')),
        );
        return;
      }

      final allContacts = await FlutterContacts.getContacts(withProperties: true);
      final contactsWithPhones = allContacts.where((c) => c.phones.isNotEmpty).toList();
      
      if (!mounted) return;
      
      if (contactsWithPhones.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay contactos con números de teléfono')),
        );
        return;
      }
      
      final selected = await showDialog<Contact?>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Seleccionar contacto'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: contactsWithPhones.length,
                itemBuilder: (_, i) {
                  final c = contactsWithPhones[i];
                  return ListTile(
                    title: Text(c.displayName),
                    subtitle: Text(c.phones.first.number),
                    onTap: () => Navigator.of(ctx).pop(c),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancelar'),
              ),
            ],
          );
        },
      );

      if (selected == null || !mounted) return;

      final name = selected.displayName;
      final phone = selected.phones.first.number;

      await _db.createContact(EmergencyContact(name: name, phoneNumber: phone));
      await _loadContacts();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contacto "$name" importado')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al importar: $e')),
      );
    }
  }

  Future<void> _callContact(String phoneNumber) async {
    await PhoneUtils.launchDialer(context, phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contactos de emergencia'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Expanded(
                      child: _contacts.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay contactos registrados aún.\n\nAgrega contactos de emergencia para llamar rápido en caso de urgencia.',
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.separated(
                              itemCount: _contacts.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final c = _contacts[i];
                                return ListTile(
                                  title: Text(c.name),
                                  subtitle: Text(c.phoneNumber),
                                  leading: const Icon(Icons.person_outline),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Llamar',
                                        icon: const Icon(Icons.call, color: Colors.green),
                                        onPressed: () => _callContact(c.phoneNumber),
                                      ),
                                      IconButton(
                                        tooltip: 'Editar',
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _addOrEditContact(existing: c),
                                      ),
                                      IconButton(
                                        tooltip: 'Eliminar',
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteContact(c),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _addOrEditContact(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar contacto'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _importFromDeviceContacts,
                      icon: const Icon(Icons.contacts),
                      label: const Text('Importar desde contactos'),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: const Floating911Button(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

