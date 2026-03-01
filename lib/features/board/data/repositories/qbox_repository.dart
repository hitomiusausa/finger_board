import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qbox.dart';
import '../models/qbox_page.dart';

class QBoxRepository {
  final SupabaseClient _supabase;

  QBoxRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // QBoxes
  Future<List<QBox>> getQBoxes() async {
    final response = await _supabase.from('qboxes').select();
    return response.map((json) => QBox.fromJson(json)).toList();
  }

  Future<QBox> getQBoxById(String id) async {
    final response = await _supabase.from('qboxes').select().eq('id', id).single();
    return QBox.fromJson(response);
  }

  Future<QBox> createQBox(QBox qbox) async {
    final response = await _supabase.from('qboxes').insert(qbox.toJson()).select().single();
    return QBox.fromJson(response);
  }

  Future<QBox> updateQBox(QBox qbox) async {
    final response = await _supabase.from('qboxes').update(qbox.toJson()).eq('id', qbox.id).select().single();
    return QBox.fromJson(response);
  }

  Future<void> deleteQBox(String id) async {
    await _supabase.from('qboxes').delete().eq('id', id);
  }

  // QBoxPages
  Future<List<QBoxPage>> getQBoxPages(String qboxId) async {
    final response = await _supabase.from('qbox_pages').select().eq('qbox_id', qboxId).order('page_index');
    return response.map((json) => QBoxPage.fromJson(json)).toList();
  }

  Future<QBoxPage> createQBoxPage(QBoxPage page) async {
    final response = await _supabase.from('qbox_pages').insert(page.toJson()).select().single();
    return QBoxPage.fromJson(response);
  }

  Future<QBoxPage> updateQBoxPage(QBoxPage page) async {
    final response = await _supabase.from('qbox_pages').update(page.toJson()).eq('id', page.id).select().single();
    return QBoxPage.fromJson(response);
  }

  Future<void> deleteQBoxPage(String id) async {
    await _supabase.from('qbox_pages').delete().eq('id', id);
  }
}
