// frontend/lib/screens/item_group_list_screen.dart
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/item_group_provider.dart";
import "../providers/store_provider.dart";
import "../screens/edit_item_group_screen.dart";
import "../widgets/app_drawer.dart";
import "../../../shared/utils/error_handler.dart";

class ItemGroupListScreen extends StatefulWidget {
  const ItemGroupListScreen({super.key});

  @override
  State<ItemGroupListScreen> createState() => _ItemGroupListScreenState();
}

class _ItemGroupListScreenState extends State<ItemGroupListScreen> {
  int? _lastStoreId;

  @override
  void initState() {
    super.initState();
    // Removed postFrame init; store changes handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule update after build to avoid marking during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final storeProvider = Provider.of<StoreProvider>(context, listen: false);
      final storeId = storeProvider.selectedStoreId;
      final hasValidStore = storeProvider.selectedStore != null;
      
      if (_lastStoreId != storeId && hasValidStore) {
        _lastStoreId = storeId;
        if (storeId != null && storeId > 0) {
          Provider.of<ItemGroupProvider>(context, listen: false).setStoreId(storeId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeId = Provider.of<StoreProvider>(context).selectedStoreId;

    // Se não houver loja selecionada, mostra uma mensagem
    if (storeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Grupos de Itens")),
        drawer: const AppDrawer(),
        body: const Center(
          child: Text("Por favor, selecione uma loja primeiro."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Grupos de Itens"),
        actions: [
          Consumer<ItemGroupProvider>(
            builder: (ctx, provider, _) => IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: provider.isLoading ? null : () => provider.fetchItemGroups(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Consumer<ItemGroupProvider>(
        builder: (ctx, groupProvider, child) {
          if (groupProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (groupProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Erro: ${groupProvider.error}"),
                  ElevatedButton(
                    onPressed: () => groupProvider.fetchItemGroups(),
                    child: const Text("Tentar Novamente"),
                  ),
                ],
              ),
            );
          }

          if (groupProvider.groups.isEmpty) {
            return const Center(
              child: Text("Nenhum grupo cadastrado."),
            );
          }

          // Lista de grupos
          return ListView.builder(
            itemCount: groupProvider.groups.length,
            itemBuilder: (ctx, index) {
              final group = groupProvider.groups[index];
              return ListTile(
                leading: const Icon(Icons.folder_open),
                title: Text(group.name),
                subtitle: Text(group.description ?? "Sem descrição"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirmar Exclusão"),
                        content: Text("Tem certeza que deseja excluir o grupo ${group.name}? Isso pode afetar itens associados."),
                        actions: [
                          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancelar")),
                          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Excluir", style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {                      try {
                        await groupProvider.deleteItemGroup(group.id);
                        ErrorHandler.showSuccessSnackBar(context, "Grupo excluído!");
                      } catch (e) {
                        ErrorHandler.showErrorSnackBar(context, "Erro ao excluir: $e");
                      }
                    }
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => EditItemGroupScreen(groupId: group.id), // Passa o ID para edição
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const EditItemGroupScreen(), // Sem ID para adição
            ),
          );
        },
      ),
    );
  }
}
