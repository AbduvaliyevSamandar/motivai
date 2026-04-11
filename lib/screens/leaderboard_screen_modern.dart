import 'package:flutter/material.dart';
import '../provider/auth_provider.dart';
import 'package:provider/provider.dart';

class LeaderboardScreenModern extends StatefulWidget {
  const LeaderboardScreenModern({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreenModern> createState() =>
      _LeaderboardScreenModernState();
}

class _LeaderboardScreenModernState extends State<LeaderboardScreenModern> {
  // Mock data - Backend'dan keladi
  final List<Map<String, dynamic>> leaderboardData = [
    {
      'rank': 1,
      'name': 'Ahmad Karim',
      'points': 5920,
      'streak': 45,
      'emoji': '👨‍💻',
    },
    {
      'rank': 2,
      'name': 'Fatima Hudayarova',
      'points': 5450,
      'streak': 38,
      'emoji': '👩‍💻',
    },
    {
      'rank': 3,
      'name': 'Samandar Abduvaliyev',
      'points': 4890,
      'streak': 32,
      'emoji': '🧑‍💻',
    },
    {
      'rank': 4,
      'name': 'Lisa Johnson',
      'points': 4320,
      'streak': 28,
      'emoji': '👩',
    },
    {
      'rank': 5,
      'name': 'Muhammad Ali',
      'points': 3850,
      'streak': 24,
      'emoji': '👨',
    },
    {
      'rank': 6,
      'name': 'Gulnara Shodmonova',
      'points': 3200,
      'streak': 18,
      'emoji': '👩‍🎓',
    },
    {
      'rank': 7,
      'name': 'Kamol Rajabov',
      'points': 2950,
      'streak': 15,
      'emoji': '👨‍🎓',
    },
    {
      'rank': 8,
      'name': 'Zarina Mirxo\'jaeva',
      'points': 2600,
      'streak': 12,
      'emoji': '🎯',
    },
    {
      'rank': 9,
      'name': 'Javohir Qo\'chqorov',
      'points': 2100,
      'streak': 8,
      'emoji': '⚡',
    },
    {
      'rank': 10,
      'name': 'Marija Ivanova',
      'points': 1850,
      'streak': 6,
      'emoji': '🌟',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2563EB),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🏆',
                        style: TextStyle(fontSize: 50),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Global Leaderboard',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Eng yaxshi o\'quvchilarni ko\'ring',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Top 3 podium
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  _buildPodiumCard(leaderboardData[1], 2),
                  SizedBox(width: 12),
                  // 1st place
                  _buildPodiumCard(leaderboardData[0], 1),
                  SizedBox(width: 12),
                  // 3rd place
                  _buildPodiumCard(leaderboardData[2], 3),
                ],
              ),
            ),
          ),
          // Rest of leaderboard
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final user = leaderboardData[index + 3];
                  return _buildLeaderboardItem(user, index + 4);
                },
                childCount: leaderboardData.length - 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(Map<String, dynamic> user, int place) {
    final heights = {1: 160.0, 2: 140.0, 3: 120.0};
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

    return Expanded(
      child: Column(
        children: [
          Text(
            medals[place] ?? '',
            style: TextStyle(fontSize: 32),
          ),
          SizedBox(height: 8),
          Container(
            height: heights[place],
            decoration: BoxDecoration(
              gradient: place == 1
                  ? LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : place == 2
                      ? LinearGradient(
                          colors: [Color(0xFFC0C0C0), Color(0xFF808080)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : LinearGradient(
                          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  user['emoji'],
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(height: 8),
                Text(
                  '#${user['rank']}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
          SizedBox(height: 8),
          Text(
            user['name'],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            '${user['points']} points',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> user, int displayRank) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: displayRank <= 10
                  ? Color(0xFF2563EB).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
            ),
            child: Center(
              child: Text(
                '#$displayRank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.whatshot,
                        size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      '${user['streak']} days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Points
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${user['points']} pts',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
