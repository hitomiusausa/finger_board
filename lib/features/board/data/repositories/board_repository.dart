import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/board.dart';
import '../models/board_page.dart';

class BoardRepository {
  final SupabaseClient _supabase;

  BoardRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  // Boards
  Future<List<Board>> fetchBoards() async {
    final response = await _supabase.from('boards').select().order('updated_at', ascending: false);
    return response.map((json) => Board.fromJson(json)).toList();
  }

  Future<Board> getBoardById(String id) async {
    final response = await _supabase.from('boards').select().eq('id', id).single();
    return Board.fromJson(response);
  }

  Future<Board> createBoard(Board board) async {
    final response = await _supabase.from('boards').insert(board.toJson()).select().single();
    return Board.fromJson(response);
  }

  Future<Board> updateBoard(Board board) async {
    final response = await _supabase.from('boards').update(board.toJson()).eq('id', board.id).select().single();
    return Board.fromJson(response);
  }

  Future<Board> updateTitle(String id, String newTitle) async {
    final response = await _supabase.from('boards').update({'title': newTitle, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id).select().single();
    return Board.fromJson(response);
  }

  Future<void> deleteBoard(String id) async {
    await _supabase.from('boards').delete().eq('id', id);
  }

  // BoardPages
  Future<List<BoardPage>> fetchPages(String boardId) async {
    final response = await _supabase.from('board_pages').select().eq('board_id', boardId).order('page_index');
    return response.map((json) => BoardPage.fromJson(json)).toList();
  }

  Future<BoardPage> createBoardPage(BoardPage page) async {
    final response = await _supabase.from('board_pages').insert(page.toJson()).select().single();
    return BoardPage.fromJson(response);
  }

  Future<BoardPage> updateBoardPage(BoardPage page) async {
    final response = await _supabase.from('board_pages').update(page.toJson()).eq('id', page.id).select().single();
    return BoardPage.fromJson(response);
  }

  Future<void> deleteBoardPage(String id) async {
    await _supabase.from('board_pages').delete().eq('id', id);
  }
}
