import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ModalChamadasGarcom {
  static void abrir(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius
                    .vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  )
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Chamadas de Garçom",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("notificacoes_garcom")
                          .where("lido", isEqualTo: false)
                          .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = snap.data!.docs
                          ..sort((a, b) {
                            final t1 =
                            (a['horario'] as Timestamp).toDate();
                            final t2 =
                            (b['horario'] as Timestamp).toDate();
                            return t2.compareTo(t1);
                          });

                        if (docs.isEmpty) {
                          return const Center(
                            child: Text(
                              "Nenhuma chamada no momento.",
                              style: TextStyle(fontSize: 16),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: controller,
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final d = docs[i];
                            final mesa = d['mesa'];
                            final horario =
                            (d['horario'] as Timestamp).toDate();

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.brown.withOpacity(0.2),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                        Colors.brown.shade400,
                                        radius: 22,
                                        child: const Icon(
                                          Icons.table_bar,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Mesa $mesa",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.brown,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(horario),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.check_circle,
                                      color: Colors.green.shade600,
                                      size: 28,
                                    ),
                                    onPressed: () async {
                                      FirebaseFirestore.instance
                                          .collection(
                                          "notificacoes_garcom")
                                          .doc(d.id)
                                          .update({"lido": true});
                                    },
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
