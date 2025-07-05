import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyAddressScreen extends StatefulWidget {
  const MyAddressScreen({super.key});

  @override
  State<MyAddressScreen> createState() => _MyAddressScreenState();
}

class _MyAddressScreenState extends State<MyAddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _addresses = [];
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final addresses = doc.data()?['addresses'] as List<dynamic>? ?? [];
          setState(() {
            _addresses = addresses
                .map((addr) => Map<String, dynamic>.from(addr))
                .toList();
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading addresses: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAddress() async {
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _postalCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final newAddress = {
          'address': _addressController.text,
          'city': _cityController.text,
          'postalCode': _postalCodeController.text,
          'isDefault': _addresses.isEmpty, // First address is default
        };

        if (_editingIndex != null) {
          // Update existing address
          final updatedAddresses = List<Map<String, dynamic>>.from(_addresses);
          updatedAddresses[_editingIndex!] = newAddress;
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'addresses': updatedAddresses});
        } else {
          // Add new address
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'addresses': FieldValue.arrayUnion([newAddress]),
          });
        }

        _addressController.clear();
        _cityController.clear();
        _postalCodeController.clear();
        _editingIndex = null;
        await _loadAddresses();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingIndex != null
                ? 'Address updated successfully'
                : 'Address added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving address: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefaultAddress(int index) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final updatedAddresses = _addresses.map((addr) {
          return {
            ...addr,
            'isDefault': addr == _addresses[index],
          };
        }).toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'addresses': updatedAddresses});

        await _loadAddresses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating default address: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAddress(int index) async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final addressToRemove = _addresses[index];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'addresses': FieldValue.arrayRemove([addressToRemove]),
        });

        await _loadAddresses();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting address: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAddressDialog([int? index]) {
    if (index != null) {
      final address = _addresses[index];
      _addressController.text = address['address'];
      _cityController.text = address['city'];
      _postalCodeController.text = address['postalCode'];
      _editingIndex = index;
    } else {
      _addressController.clear();
      _cityController.clear();
      _postalCodeController.clear();
      _editingIndex = null;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(index != null ? 'Edit Alamat' : 'Tambah Alamat Baru',
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF295D49))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      const Icon(Icons.home_outlined, color: Color(0xFF295D49)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'Kota',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon:
                      const Icon(Icons.location_city, color: Color(0xFF295D49)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _postalCodeController,
                decoration: InputDecoration(
                  labelText: 'Kode Pos',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.local_post_office,
                      color: Color(0xFF295D49)),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addressController.clear();
              _cityController.clear();
              _postalCodeController.clear();
              _editingIndex = null;
            },
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF7F8C8D))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveAddress();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF295D49),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Alamat Saya",
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Color(0xFF295D49)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF295D49)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF295D49)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _addresses.isEmpty
                      ? SizedBox(
                          height: 400,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.location_off,
                                  size: 80,
                                  color: Color(0xFF7F8C8D),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada alamat',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF7F8C8D),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tambahkan alamat pertama Anda',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF7F8C8D),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final address = _addresses[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        if (address['isDefault'] == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF295D49)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.star,
                                                    color: Color(0xFF295D49),
                                                    size: 16),
                                                SizedBox(width: 4),
                                                Text('Utama',
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF295D49),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          )
                                        else
                                          InkWell(
                                            onTap: () =>
                                                _setDefaultAddress(index),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF295D49)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Row(
                                                children: [
                                                  Icon(Icons.star_border,
                                                      color: Color(0xFF295D49),
                                                      size: 16),
                                                  SizedBox(width: 4),
                                                  Text('Jadikan Utama',
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xFF295D49),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Color(0xFF295D49)),
                                              onPressed: () =>
                                                  _showAddressDialog(index),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _deleteAddress(index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF295D49)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.location_on,
                                              color: Color(0xFF295D49),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                address['address'],
                                                style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF3D5154)),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${address['city']}, ${address['postalCode']}',
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF7F8C8D)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _showAddressDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF295D49),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Tambah Alamat',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
