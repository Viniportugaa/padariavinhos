import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padariavinhos/models/produto.dart';
import 'package:go_router/go_router.dart';
import 'package:padariavinhos/helpers/dialog_helper.dart';

class AdminProdutosPage extends StatefulWidget {
  @override
  State<AdminProdutosPage> createState() => _AdminProdutosPageState();
}

class _AdminProdutosPageState extends State<AdminProdutosPage> {

  final List<String> categoriasFixas = [
    'Todas',
    'Festividade','Pratos','Doce','Lanches',
    'Bolos','Paes','Refrigerante','Salgados','Sucos','Combo'
  ];

  /// CALCULO AUTOMATICO
  bool calcularDisponivelAutomatico(List<String> diasDisponiveis){

    final hoje = DateTime.now().weekday;

    const dias = {
      1:"segunda",
      2:"terca",
      3:"quarta",
      4:"quinta",
      5:"sexta",
      6:"sabado",
      7:"domingo"
    };

    final diaHoje = dias[hoje]!;

    if(diasDisponiveis.contains("all")) return true;

    return diasDisponiveis.contains(diaHoje);
  }


  /// EDITAR PRODUTO
  void _editarProduto(BuildContext context, Produto produto){

    final nomeController=TextEditingController(text:produto.nome);
    final descricaoController=TextEditingController(text:produto.descricao);
    final precoController=TextEditingController(text:produto.preco.toString());

    String categoria=produto.category;
    bool disponivelLocal=produto.disponivelLocal;
    bool vendidoPorPeso=produto.vendidoPorPeso;

    List<String> diasSelecionados=List.from(produto.diasDisponiveis);

    const diasSemana=[
      'segunda','terca','quarta',
      'quinta','sexta','sabado','domingo'
    ];

    showModalBottomSheet(

        context:context,
        isScrollControlled:true,

        builder:(context){

          return StatefulBuilder(

              builder:(context,setModalState){

                return Padding(

                    padding:EdgeInsets.only(
                        bottom:MediaQuery.of(context).viewInsets.bottom+16,
                        top:16,left:16,right:16
                    ),

                    child:SingleChildScrollView(

                        child:Column(

                            children:[

                              const Text(
                                'Editar Produto',
                                style:TextStyle(
                                    fontSize:20,
                                    fontWeight:FontWeight.bold),
                              ),

                              const SizedBox(height:16),

                              TextField(
                                controller:nomeController,
                                decoration:const InputDecoration(
                                  labelText:"Nome",
                                  border:OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height:12),

                              TextField(
                                controller:descricaoController,
                                maxLines:2,
                                decoration:const InputDecoration(
                                  labelText:"Descrição",
                                  border:OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height:12),

                              TextField(
                                controller:precoController,
                                keyboardType:TextInputType.number,
                                decoration:const InputDecoration(
                                  labelText:"Preço",
                                  prefixText:"R\$ ",
                                  border:OutlineInputBorder(),
                                ),
                              ),

                              const SizedBox(height:12),

                              DropdownButtonFormField<String>(

                                value:categoria,

                                items:categoriasFixas
                                    .where((c)=>c!="Todas")
                                    .map((c)=>DropdownMenuItem(
                                    value:c,
                                    child:Text(c)
                                )).toList(),

                                onChanged:(v){
                                  if(v!=null){
                                    setModalState(()=>categoria=v);
                                  }
                                },

                                decoration:const InputDecoration(
                                  labelText:"Categoria",
                                  border:OutlineInputBorder(),
                                ),

                              ),

                              const SizedBox(height:12),

                              SwitchListTile(
                                value:disponivelLocal,
                                title:const Text("Disponível Local"),
                                onChanged:(v){
                                  setModalState(()=>disponivelLocal=v);
                                },
                              ),

                              SwitchListTile(
                                value:vendidoPorPeso,
                                title:const Text("Vendido por peso"),
                                onChanged:(v){
                                  setModalState(()=>vendidoPorPeso=v);
                                },
                              ),

                              const SizedBox(height:10),

                              const Text(
                                "Disponibilidade por dia",
                                style:TextStyle(
                                    fontWeight:FontWeight.bold),
                              ),

                              CheckboxListTile(
                                title:const Text("Todos os dias"),
                                value:diasSelecionados.contains("all"),
                                onChanged:(v){

                                  setModalState((){

                                    diasSelecionados.clear();

                                    if(v==true){
                                      diasSelecionados.add("all");
                                    }

                                  });

                                },

                              ),

                              ...diasSemana.map((dia){

                                return CheckboxListTile(

                                  title:Text(dia),

                                  value:diasSelecionados.contains(dia),

                                  onChanged:(v){

                                    setModalState((){

                                      diasSelecionados.remove("all");

                                      if(v==true){
                                        diasSelecionados.add(dia);
                                      }else{
                                        diasSelecionados.remove(dia);
                                      }

                                    });

                                  },

                                );

                              }),

                              const SizedBox(height:20),

                              ElevatedButton.icon(

                                icon:const Icon(Icons.save),

                                label:const Text("Salvar"),

                                style:ElevatedButton.styleFrom(
                                    backgroundColor:Colors.deepOrange
                                ),

                                onPressed:() async{

                                  final disponivelAutomatico=
                                  calcularDisponivelAutomatico(
                                      diasSelecionados);

                                  await FirebaseFirestore.instance
                                      .collection('produtos')
                                      .doc(produto.id)
                                      .update({

                                    'nome':nomeController.text.trim(),

                                    'descricao':
                                    descricaoController.text.trim(),

                                    'preco':double.tryParse(
                                        precoController.text
                                            .replaceAll(',', '.'))
                                        ??produto.preco,

                                    'category':categoria,

                                    'diasDisponiveis':diasSelecionados,

                                    'disponivel':disponivelAutomatico,

                                    'disponivelLocal':disponivelLocal,

                                    'vendidoPorPeso':vendidoPorPeso,

                                    'imageUrl':produto.imageUrl

                                  });

                                  Navigator.pop(context);

                                  DialogHelper.showTemporaryToast(
                                      context,
                                      "Produto atualizado");

                                  setState((){});

                                },

                              ),

                              const SizedBox(height:20)

                            ]

                        )

                    )

                );

              }

          );

        }

    );

  }


  /// TOGGLE DISPONIVEL
  void toggleDisponivel(String id,bool atual) async{

    await FirebaseFirestore.instance
        .collection('produtos')
        .doc(id)
        .update({'disponivel':!atual});

  }


  /// DELETE
  void _confirmarExclusaoProduto(
      String id,String nome) async{

    final confirm=await showDialog<bool>(

        context:context,

        builder:(context)=>AlertDialog(

            title:const Text("Excluir produto"),

            content:Text("Excluir '$nome'?"),

            actions:[

              TextButton(
                  onPressed:()=>Navigator.pop(context,false),
                  child:const Text("Cancelar")
              ),

              ElevatedButton(

                  style:ElevatedButton.styleFrom(
                      backgroundColor:Colors.red),

                  onPressed:()=>Navigator.pop(context,true),

                  child:const Text("Excluir")

              )

            ]

        )

    );

    if(confirm==true){

      await FirebaseFirestore.instance
          .collection('produtos')
          .doc(id)
          .delete();

      DialogHelper.showTemporaryToast(
          context,
          "Produto excluído");

    }

  }


  @override
  Widget build(BuildContext context){

    return Scaffold(

        appBar:AppBar(
            title:const Text('Painel Admin - Produtos'),
            backgroundColor:Colors.deepOrange
        ),

        floatingActionButton:FloatingActionButton(
          backgroundColor:Colors.deepOrange,
          onPressed:()=>context.go('/cadastro-produto'),
          child:const Icon(Icons.add),
        ),

        body:StreamBuilder<QuerySnapshot>(

            stream:FirebaseFirestore.instance
                .collection('produtos')
                .snapshots(),

            builder:(context,snapshot){

              if(!snapshot.hasData){
                return const Center(
                    child:CircularProgressIndicator());
              }

              final docs=snapshot.data!.docs;

              return GridView.builder(

                  padding:const EdgeInsets.all(12),

                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:2,
                      crossAxisSpacing:12,
                      mainAxisSpacing:12,
                      childAspectRatio:0.75
                  ),

                  itemCount:docs.length,

                  itemBuilder:(context,i){

                    final produto=Produto.fromMap(
                        docs[i].data()
                        as Map<String,dynamic>,
                        docs[i].id
                    );

                    return Container(

                        decoration:BoxDecoration(

                            color:Colors.white,

                            borderRadius:
                            BorderRadius.circular(16),

                            boxShadow:[

                              BoxShadow(
                                  color:Colors.black12,
                                  blurRadius:6)

                            ]

                        ),

                        child:Column(

                            children:[

                              Expanded(

                                  child:ClipRRect(

                                      borderRadius:
                                      const BorderRadius.vertical(
                                          top:Radius.circular(16)),

                                      child:
                                      produto.imageUrl.isNotEmpty

                                          ?Image.network(
                                          produto.imageUrl.first,
                                          fit:BoxFit.cover)

                                          :const Icon(
                                          Icons.fastfood,
                                          size:50)

                                  )

                              ),

                              Padding(

                                  padding:
                                  const EdgeInsets.all(8),

                                  child:Column(

                                      children:[

                                        Text(
                                          produto.nome,
                                          maxLines:1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style:
                                          const TextStyle(
                                              fontWeight:
                                              FontWeight.bold),
                                        ),

                                        Text(
                                            "R\$ ${produto.preco.toStringAsFixed(2)}"
                                        ),

                                        const SizedBox(height:6),

                                        Row(

                                            children:[

                                              Expanded(

                                                  child:
                                                  ElevatedButton(

                                                      style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          produto.disponivel
                                                              ?Colors.green
                                                              :Colors.red),

                                                      onPressed:(){

                                                        toggleDisponivel(
                                                            produto.id,
                                                            produto.disponivel);

                                                      },

                                                      child:
                                                      const Icon(Icons.store)

                                                  )

                                              ),

                                              const SizedBox(width:5),

                                              Expanded(

                                                  child:
                                                  ElevatedButton(

                                                      style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          Colors.orange),

                                                      onPressed:(){

                                                        _editarProduto(
                                                            context,
                                                            produto);

                                                      },

                                                      child:
                                                      const Icon(Icons.edit)

                                                  )

                                              ),

                                              const SizedBox(width:5),

                                              Expanded(

                                                  child:
                                                  ElevatedButton(

                                                      style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                          Colors.black),

                                                      onPressed:(){

                                                        _confirmarExclusaoProduto(
                                                            produto.id,
                                                            produto.nome);

                                                      },

                                                      child:
                                                      const Icon(Icons.delete)

                                                  )

                                              )

                                            ]

                                        )

                                      ]

                                  )

                              )

                            ]

                        )

                    );

                  }

              );

            }

        )

    );

  }

}