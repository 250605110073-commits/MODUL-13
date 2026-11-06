
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const Modul13App());
}

class Modul13App extends StatelessWidget {
  const Modul13App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modul 13 CRUD',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Post {
  final int id;
  final int apiId;
  final int userId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.apiId,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final int serverId = json['id'] as int;

    return Post(
      id: serverId,
      apiId: serverId,
      userId: json['userId'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Post copyWith({
    String? title,
    String? body,
  }) {
    return Post(
      id: id,
      apiId: apiId,
      userId: userId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String baseUrl =
      'https://jsonplaceholder.typicode.com';

  final List<Post> posts = [];

  bool isLoading = false;
  String? loadError;

  int nextLocalId = -1;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // READ: Mengambil data dari API
  Future<void> fetchPosts() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/posts?_limit=10'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          posts
            ..clear()
            ..addAll(
              data.map(
                (item) => Post.fromJson(item),
              ),
            );
        });
      } else {
        throw Exception(
          'Gagal mengambil data: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        loadError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // CREATE: Menambahkan data baru
  Future<void> createPost(
    String title,
    String body,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'title': title,
          'body': body,
          'userId': 1,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        final newPost = Post(
          id: nextLocalId,
          apiId: data['id'] as int,
          userId: 1,
          title: title,
          body: body,
        );

        nextLocalId--;

        setState(() {
          posts.insert(0, newPost);
        });

        showMessage('Data berhasil ditambahkan');
      } else {
        showMessage(
          'Data gagal ditambahkan: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      showMessage('Terjadi kesalahan: $e');
    }
  }

  // UPDATE: Mengubah data yang dipilih
  Future<void> updatePost(
    Post selectedPost,
    String title,
    String body,
  ) async {
    bool serverUpdated = false;
    String serverError = '';

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/posts/${selectedPost.apiId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'id': selectedPost.apiId,
          'title': title,
          'body': body,
          'userId': selectedPost.userId,
        }),
      );

      if (response.statusCode == 200) {
        serverUpdated = true;
      } else {
        serverError = 'HTTP ${response.statusCode}';
      }
    } catch (e) {
      serverError = e.toString();
    }

    if (!mounted) return;

    setState(() {
      final index = posts.indexWhere(
        (post) => post.id == selectedPost.id,
      );

      if (index != -1) {
        posts[index] = selectedPost.copyWith(
          title: title,
          body: body,
        );
      }
    });

    if (serverUpdated) {
      showMessage('Data berhasil diperbarui');
    } else {
      showMessage(
        'Data diperbarui di aplikasi. Server: $serverError',
      );
    }
  }

  // DELETE: Menghapus satu data yang dipilih
  Future<void> deletePost(Post selectedPost) async {
    bool serverDeleted = false;
    String serverError = '';

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/posts/${selectedPost.apiId}'),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204) {
        serverDeleted = true;
      } else {
        serverError = 'HTTP ${response.statusCode}';
      }
    } catch (e) {
      serverError = e.toString();
    }

    if (!mounted) return;

    setState(() {
      posts.removeWhere(
        (post) => post.id == selectedPost.id,
      );
    });

    if (serverDeleted) {
      showMessage('Data berhasil dihapus');
    } else {
      showMessage(
        'Data dihapus dari aplikasi. Server: $serverError',
      );
    }
  }

  // Form tambah dan edit data
  void showPostDialog({Post? post}) {
    final isEdit = post != null;

    final titleController = TextEditingController(
      text: post?.title ?? '',
    );

    final bodyController = TextEditingController(
      text: post?.body ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            isEdit ? 'Edit Data' : 'Tambah Data',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bodyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Data',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                titleController.dispose();
                bodyController.dispose();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final body = bodyController.text.trim();

                if (title.isEmpty || body.isEmpty) {
                  showMessage('Semua kolom harus diisi');
                  return;
                }

                Navigator.pop(dialogContext);

                if (isEdit) {
                  updatePost(post, title, body);
                } else {
                  createPost(title, body);
                }

                titleController.dispose();
                bodyController.dispose();
              },
              child: Text(
                isEdit ? 'Simpan' : 'Tambah',
              ),
            ),
          ],
        );
      },
    );
  }

  // Konfirmasi sebelum menghapus
  void confirmDelete(Post post) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Data'),
          content: Text(
            'Apakah kamu yakin ingin menghapus "${post.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                deletePost(post);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Modul 13 - CRUD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: isLoading ? null : fetchPosts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: isLoading && posts.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : loadError != null && posts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(loadError!),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: fetchPosts,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : posts.isEmpty
                  ? const Center(
                      child: Text('Belum ada data'),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchPosts,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];

                          return Card(
                            margin: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(post.body),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () {
                                          showPostDialog(
                                            post: post,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Hapus',
                                        onPressed: () {
                                          confirmDelete(post);
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
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
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showPostDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Data'),
      ),
    );
  }
}
