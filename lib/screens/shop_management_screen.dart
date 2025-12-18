import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:smart_greenhouse/l10n/app_localizations.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

class ShopManagementScreen extends StatefulWidget {
  const ShopManagementScreen({super.key});

  @override
  State<ShopManagementScreen> createState() => _ShopManagementScreenState();
}

class _ShopManagementScreenState extends State<ShopManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.userId != null) {
        context.read<CartProvider>().fetchUserProducts(auth.userId!);
        context.read<CartProvider>().fetchSales(auth.userId!);
      }
    });
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    XFile? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(AppLocalizations.of(context).postNewSeed),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() => selectedImage = image);
                      }
                    },
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: selectedImage != null
                          ? kIsWeb
                                ? Image.network(
                                    selectedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                  )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, size: 40),
                                Text(AppLocalizations.of(context).addPhoto),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).seedName,
                    ),
                    validator: (v) => v?.isEmpty == true
                        ? AppLocalizations.of(context).required
                        : null,
                  ),
                  TextFormField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).description,
                    ),
                    maxLines: 2,
                  ),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context).price} (\$)',
                      prefixText: '\$ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true
                        ? AppLocalizations.of(context).required
                        : null,
                  ),
                  TextFormField(
                    controller: stockController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).stockQuantity,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty == true
                        ? AppLocalizations.of(context).required
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isUploading = true);
                        final provider = context.read<CartProvider>();
                        final authProvider = context.read<AuthProvider>();
                        String? imageUrl;

                        if (selectedImage != null) {
                          imageUrl = await provider.uploadImage(
                            selectedImage!,
                            userId: authProvider.userId,
                          );
                          if (imageUrl == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context).uploadFailed,
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              setState(() => isUploading = false);
                            }
                            return;
                          }
                        }

                        final success = await provider.addProduct(
                          nameController.text,
                          descController.text,
                          double.tryParse(priceController.text) ?? 0.0,
                          int.tryParse(stockController.text) ?? 0,
                          imageUrl: imageUrl,
                          userId: authProvider.userId,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? AppLocalizations.of(context).postSuccess
                                    : AppLocalizations.of(context).postFailed,
                              ),
                              backgroundColor: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context).post),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).myShopManagement),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        label: Text(AppLocalizations.of(context).postNewSeed),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final earnings = cart.totalEarnings;

          return Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context).totalEarnings,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '\$${earnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: cart.userProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.store_mall_directory,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context).noSeedsPosted),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.userProducts.length,
                        itemBuilder: (context, index) {
                          final product = cart.userProducts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: product.imageUrl.startsWith('assets/')
                                      ? Image.asset(
                                          product.imageUrl,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          product.imageUrl.startsWith('http')
                                              ? product.imageUrl
                                              : '${cart.apiUrl}/${product.imageUrl}',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(
                                                    Icons.broken_image,
                                                  ),
                                        ),
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(
                                '\$${product.price.toStringAsFixed(2)} • Stock: ${product.stock}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).deleteProduct,
                                      ),
                                      content: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).deleteConfirm,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text(
                                            AppLocalizations.of(context).cancel,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text(
                                            AppLocalizations.of(context).delete,
                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    final success = await cart.deleteProduct(
                                      product.id,
                                    );
                                    if (success && context.mounted) {
                                      // Refresh user products
                                      if (auth.userId != null) {
                                        cart.fetchUserProducts(auth.userId!);
                                      }
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).productDeleted,
                                          ),
                                        ),
                                      );
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            AppLocalizations.of(
                                              context,
                                            ).deleteFailed,
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
