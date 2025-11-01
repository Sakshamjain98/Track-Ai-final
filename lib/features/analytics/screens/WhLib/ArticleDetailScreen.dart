// lib/ArticleDetailScreen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

// Import the Article model from InsightsScreen.dart
import 'InsightsScreen.dart';
// --- IMPORT THE NEW REVIEWER SCREEN ---

class ArticleDetailScreen extends StatelessWidget {
  final Article article;
  const ArticleDetailScreen({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Article background is white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ARTICLE CONTENT ---
            Text(
              article.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            // --- MOVED REVIEWER CARD HERE ---
            _buildReviewerSummaryCard(context),
            // ---------------------------------

            const SizedBox(height: 24),
            // --- FIXED ARTICLE IMAGE LOADING ---
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  color: Colors.grey[200], // Placeholder color
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE91E63),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 50,
                      );
                    },
                  ),
                ),
              ),
            // ---------------------------------

            // Use MarkdownBody to render formatted text
            MarkdownBody(
              data: article.content,
              selectable: true,
              styleSheet:
              MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: const TextStyle(
                  fontSize: 16,
                  height: 1.6, // Line spacing
                  color: Colors.black87,
                ),
              ),
              onTapLink: (text, href, title) {
                if (href != null) {
                  launchUrl(Uri.parse(href));
                }
              },
            ),

            // --- ADDED TAKEAWAY SECTION ---
            if (article.takeaway.isNotEmpty)
              _buildTakeawaySection(context, article.takeaway),

            // --- ADDED REFERENCES SECTION ---
            if (article.references.isNotEmpty)
              _buildReferencesSection(context, article.references),
          ],
        ),
      ),
    );
  }

  // --- NEW: TAKEAWAY WIDGET ---
  Widget _buildTakeawaySection(BuildContext context, String takeaway) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6F1).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "The takeaway",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            takeaway,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // --- NEW: REFERENCES WIDGET ---
  Widget _buildReferencesSection(BuildContext context, List<String> references) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "References",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          // Using Column to build the list
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(references.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  "${index + 1}. ${references[index]}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- UPDATED CLICKABLE REVIEWER SUMMARY CARD ---
  Widget _buildReviewerSummaryCard(BuildContext context) {
    String reviewerName = article.reviewer['name'] ?? 'N/A';
    String reviewerTitle = article.reviewer['title'] ?? '';
    String reviewerImageUrl = article.reviewer['imageUrl'] ?? '';

    return GestureDetector(
      // --- UPDATED ONTAP TO PUSH NEW SCREEN ---
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ReviewerDetailScreen(reviewer: article.reviewer),
          ),
        );
      },
      // ----------------------------------------
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // --- FIXED REVIEWER IMAGE LOADING ---
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFF5E6F1),
              child: ClipOval(
                child: reviewerImageUrl.isNotEmpty
                    ? Image.network(
                  reviewerImageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE91E63),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      color: Color(0xFFE91E63),
                      size: 30,
                    );
                  },
                )
                    : const Icon(
                  Icons.person,
                  color: Color(0xFFE91E63),
                  size: 30,
                ),
              ),
            ),
            // ------------------------------------
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Reviewed by",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reviewerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (reviewerTitle.isNotEmpty)
                    Text(
                      reviewerTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }

// --- REMOVED _showReviewerProfileModal and _ReviewerProfileSheet ---
// The profile logic is now in ReviewerDetailScreen.dart
}


class ReviewerDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reviewer;

  const ReviewerDetailScreen({Key? key, required this.reviewer})
      : super(key: key);

  // Helper to safely get reviewer data
  String get reviewerName => reviewer['name'] ?? 'N/A';
  String get reviewerTitle => reviewer['title'] ?? '';
  String get reviewerImageUrl => reviewer['imageUrl'] ?? '';
  String get reviewerLocation => reviewer['location'] ?? '';
  String get reviewerQuote => reviewer['quote'] ?? '';
  String get linkedInUrl => reviewer['linkedInUrl'] ?? '';
  List<String> get expertise => List<String>.from(reviewer['expertise'] ?? []);
  List<String> get education => List<String>.from(reviewer['education'] ?? []);
  List<String> get awards => List<String>.from(reviewer['awards'] ?? []);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Add a back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // Optional: Add a title
        title: const Text(
          'Medical Reviewer',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- This is the layout from your OLD screen ---
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // --- FIXED REVIEWER IMAGE LOADING ---
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFF5E6F1),
                    child: ClipOval(
                      child: reviewerImageUrl.isNotEmpty
                          ? Image.network(
                        reviewerImageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFE91E63),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.person,
                            color: Color(0xFFE91E63),
                            size: 50,
                          );
                        },
                      )
                          : const Icon(
                        Icons.person,
                        color: Color(0xFFE91E63),
                        size: 50,
                      ),
                    ),
                  ),
                  // ------------------------------------
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.teal, // Checkmark color
                        shape: BoxShape.circle,
                      ),
                      child:
                      const Icon(Icons.check, color: Colors.white, size: 16),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                reviewerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            if (linkedInUrl.isNotEmpty)
              Center(
                child: IconButton(
                  icon:
                  const Icon(Icons.launch_sharp, color: Color(0xFF0A66C2)),
                  onPressed: () async {
                    final uri = Uri.parse(linkedInUrl);
                    if (!await launchUrl(uri,
                        mode: LaunchMode.externalApplication)) {
                      // Handle error
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '$reviewerTitle\n$reviewerLocation',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (reviewerQuote.isNotEmpty)
              Center(
                child: Text(
                  '"$reviewerQuote"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              ),

            // --- EXPERTISE, EDUCATION, AWARDS ---
            if (expertise.isNotEmpty)
              ..._buildProfileSection("Areas of Expertise", expertise,
                  isBulletPoints: false),

            if (education.isNotEmpty)
              ..._buildProfileSection("Education", education,
                  isBulletPoints: true),

            if (awards.isNotEmpty)
              ..._buildProfileSection("Awards and achievements", awards,
                  isBulletPoints: true),
          ],
        ),
      ),
    );
  }

  // Helper to build profile sections like in the images
  List<Widget> _buildProfileSection(String title, List<String> items,
      {bool isBulletPoints = true}) {
    return [
      const SizedBox(height: 24),
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      const SizedBox(height: 12),
      if (!isBulletPoints) // For "Areas of Expertise"
        Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                item,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500),
              ),
            ))
                .toList()
                .cast<Widget>(), // Ensure correct type
          ),
        )
      else // For "Education" and "Awards"
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6.0, right: 8.0),
                  child: Icon(Icons.circle, size: 8, color: Colors.teal),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ))
              .toList()
              .cast<Widget>(), // Ensure correct type
        ),
    ];
  }
}