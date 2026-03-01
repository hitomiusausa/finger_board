import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/board_object.dart';
import '../models/board_object_child.dart';

class BoardObjectRepository {
  final SupabaseClient _supabase;

  BoardObjectRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // BoardObjects
  Future<List<BoardObject>> getBoardObjects(String pageId) async {
    final response = await _supabase
        .from('board_objects')
        .select()
        .eq('page_id', pageId)
        .order('z_index');
    return response.map((json) => BoardObject.fromJson(json)).toList();
  }

  Future<BoardObject> getBoardObjectById(String id) async {
    final response = await _supabase.from('board_objects').select().eq('id', id).single();
    return BoardObject.fromJson(response);
  }

  Future<BoardObject> createBoardObject(BoardObject boardObject) async {
    final response = await _supabase.from('board_objects').insert(boardObject.toJson()).select().single();
    return BoardObject.fromJson(response);
  }

  Future<BoardObject> updateBoardObject(BoardObject boardObject) async {
    final response = await _supabase.from('board_objects').update(boardObject.toJson()).eq('id', boardObject.id).select().single();
    return BoardObject.fromJson(response);
  }

  Future<void> deleteBoardObject(String id) async {
    await _supabase.from('board_objects').delete().eq('id', id);
  }

  // BoardObjectChildren
  Future<List<BoardObjectChild>> getBoardObjectChildren(String boardObjectId) async {
    final response = await _supabase
        .from('board_object_children')
        .select()
        .eq('board_object_id', boardObjectId)
        .order('child_index');
    return response.map((json) => BoardObjectChild.fromJson(json)).toList();
  }

  Future<BoardObjectChild> createBoardObjectChild(BoardObjectChild child) async {
    final response = await _supabase.from('board_object_children').insert(child.toJson()).select().single();
    return BoardObjectChild.fromJson(response);
  }

  Future<BoardObjectChild> updateBoardObjectChild(BoardObjectChild child) async {
    final response = await _supabase.from('board_object_children').update(child.toJson()).eq('id', child.id).select().single();
    return BoardObjectChild.fromJson(response);
  }

  Future<void> deleteBoardObjectChild(String id) async {
    await _supabase.from('board_object_children').delete().eq('id', id);
  }
}
