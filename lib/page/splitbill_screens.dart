import 'package:flutter/material.dart';
import 'package:billo_app/models/bill_model.dart';
import 'package:billo_app/page/result_screens.dart';
import 'package:billo_app/utils/price_utils.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SplitBillScreen extends StatefulWidget {
  final List<BillItem> initialItems;
  final String? receiptImagePath;

  const SplitBillScreen({
    super.key,
    required this.initialItems,
    this.receiptImagePath,
  });

  @override
  _SplitBillScreenState createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends State<SplitBillScreen>
    with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF37474F);
  final Color _accentColor = const Color(0xFF26A69A);
  final Color _bgColor = const Color(0xFFF5F7FA);
  final Color _surfaceColor = Colors.white;
  final Color _borderColor = const Color(0xFFE1E5E9);
  final Color _textSecondary = const Color(0xFF64748B);
  final Color _successColor = const Color(0xFF10B981);
  final Color _warningColor = const Color(0xFFF59E0B);
  final Color _shadowColor = const Color(0x0C000000);
  final Color _textPrimary = const Color(0xFF0F172A);

  late List<BillItem> _items;
  late List<Participant> _participants;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final PageController _tutorialController = PageController();

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'icon': Icons.group_add_rounded,
      'title': 'Add Participants',
      'description': 'Enter names and phone numbers of everyone sharing the bill',
    },
    {
      'icon': Icons.receipt_long_rounded,
      'title': 'Add Items',
      'description': 'List all items from the bill with their prices',
    },
    {
      'icon': Icons.link_rounded,
      'title': 'Assign Items',
      'description': 'Assign each item to specific participants',
    },
    {
      'icon': Icons.calculate_rounded,
      'title': 'Calculate',
      'description': 'Get detailed breakdown of who pays what',
    },
  ];

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
    _participants = [];
    _tabController = TabController(length: 2, vsync: this);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_items.isEmpty && _participants.isEmpty) {
        _showTutorial();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _tutorialController.dispose();
    super.dispose();
  }

  void _showTutorial() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TutorialOverlay(
        tutorialSteps: _tutorialSteps,
        accentColor: _accentColor,
        primaryColor: _primaryColor,
        onClose: () {},
      ),
    );
  }

  void _showAddParticipantDialog() {
    _nameController.clear();
    _phoneController.clear();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddParticipantDialog(
        nameController: _nameController,
        phoneController: _phoneController,
        accentColor: _accentColor,
        textSecondary: _textSecondary,
        primaryColor: _primaryColor,
        onSave: () {
          _addParticipant();
        },
      ),
    );
  }

  void _addParticipant() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      _showError('Name and phone number are required');
      return;
    }

    final phoneRegex = RegExp(r'^(08\d{8,11}|62\d{9,12}|\+62\d{9,12})$');
    if (!phoneRegex.hasMatch(phone)) {
      _showError('Invalid phone number format. Use 08 or +62 format');
      return;
    }

    final participant = Participant(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      phoneNumber: phone,
    );
    setState(() {
      _participants.add(participant);
    });
    _nameController.clear();
    _phoneController.clear();
    Navigator.pop(context);
    _showAddSuccess('Participant added successfully!');
  }

  void _showAddSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: _successColor),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _surfaceColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeParticipant(String id) {
    setState(() {
      _participants.removeWhere((p) => p.id == id);

      for (var item in _items) {
        item.assignedTo.removeWhere((participantId) => participantId == id);
      }
    });
  }

  void _addItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemDialog(
        participants: _participants,
        accentColor: _accentColor,
        textSecondary: _textSecondary,
        primaryColor: _primaryColor,
        onSave: (itemName, quantity, pricePerUnit, selectedParticipants) {
          final totalPrice = quantity * pricePerUnit;
          setState(() {
            _items.add(
              BillItem(
                name: itemName,
                quantity: quantity,
                pricePerUnit: pricePerUnit,
                totalPrice: totalPrice,
                assignedTo: selectedParticipants,
              ),
            );
          });
          _showAddSuccess('Item added successfully!');
        },
      ),
    );
  }

  void _editItem(int index) {
    final item = _items[index];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemDialog(
        itemName: item.name,
        quantity: item.quantity,
        pricePerUnit: item.pricePerUnit,
        selectedParticipants: item.assignedTo,
        participants: _participants,
        accentColor: _accentColor,
        textSecondary: _textSecondary,
        primaryColor: _primaryColor,
        onSave: (itemName, quantity, pricePerUnit, selectedParticipants) {
          final totalPrice = quantity * pricePerUnit;
          setState(() {
            _items[index] = item.copyWith(
              name: itemName,
              quantity: quantity,
              pricePerUnit: pricePerUnit,
              totalPrice: totalPrice,
              assignedTo: selectedParticipants,
            );
          });
        },
      ),
    );
  }

  void _removeItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _surfaceColor,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline, color: Colors.red.shade600),
            ),
            const SizedBox(width: 12),
            const Text(
              'Delete Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _textSecondary),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _calculateSplit() {
    if (_participants.isEmpty) {
      _showError('Add at least one participant');
      return;
    }

    if (_items.isEmpty) {
      _showError('Add at least one item');
      return;
    }

    for (var item in _items) {
      if (item.assignedTo.isEmpty) {
        _showError('All items must be assigned to at least one participant');
        return;
      }
    }

    final billData = BillData(
      items: _items,
      participants: _participants,
      receiptImagePath: widget.receiptImagePath,
      createdDate: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ResultScreen(billData: billData)),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = _items.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final double perPerson = _participants.isNotEmpty
        ? totalAmount / _participants.length
        : 0;
    final hasScannedItems = widget.initialItems.isNotEmpty;
    final isItemsEmpty = _items.isEmpty;
    final isParticipantsEmpty = _participants.isEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(totalAmount, perPerson, hasScannedItems),
            Container(
              color: _surfaceColor,
              child: TabBar(
                controller: _tabController,
                labelColor: _accentColor,
                unselectedLabelColor: _textSecondary,
                indicatorColor: _accentColor,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('Participants'),
                        if (_participants.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_participants.length}',
                              style: TextStyle(
                                color: _accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 18),
                        const SizedBox(width: 8),
                        const Text('Bill Items'),
                        if (_items.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_items.length}',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildParticipantsTab(isParticipantsEmpty),
                  _buildItemsTab(isItemsEmpty, totalAmount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    double totalAmount,
    double perPerson,
    bool hasScannedItems,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, _primaryColor.withOpacity(0.95)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Billo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SG03Custom',
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, -12),
                    child: Text(
                      'Smart bill splitting made easy',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _showTutorial,
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _accentColor,
                  ),
                  child: Icon(
                    FontAwesomeIcons.lightbulb,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Per Person',
                  PriceUtils.formatPrice(perPerson),
                  Icons.person_rounded,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.2),
                      Colors.blueAccent.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Bill',
                  PriceUtils.formatPrice(totalAmount),
                  Icons.receipt_long_rounded,
                  gradient: LinearGradient(
                    colors: [
                      _accentColor.withOpacity(0.2),
                      _accentColor.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            height: 103,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.group_add_rounded,
                        label: 'Add People',
                        onPressed: _showAddParticipantDialog,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        iconColor: Colors.white,
                        textColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_rounded,
                        label: 'Add Item',
                        onPressed: _addItem,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        iconColor: Colors.white,
                        textColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 46,
                  child: _buildActionButton(
                    icon: Icons.calculate_rounded,
                    label: 'Calculate',
                    onPressed: _calculateSplit,
                    backgroundColor: _accentColor,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    bool isPrimary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: Colors.white.withOpacity(0.2), width: 1),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon, {
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        gradient: gradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.9), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(bool isEmpty) {
    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add People Card - SAMA SEPERTI ADD ITEM
          _buildAddPeopleCard(),
          const SizedBox(height: 24),

          // Participants List
          if (!isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Participants List',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _participants.length.toString(),
                        style: TextStyle(
                          color: _accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    final participant = _participants[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(18),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          leading: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _accentColor.withOpacity(0.2),
                                  _accentColor.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                participant.name.substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: _accentColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            participant.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _textPrimary,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone_rounded,
                                  size: 14,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  participant.phoneNumber,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                            icon: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                            ),
                            onPressed: () => _removeParticipant(participant.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          else
            // Empty State
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.group_rounded,
                      size: 56,
                      color: _borderColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Participants Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add participants using the button above to start splitting the bill',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Add People Card (SAMA SEPERTI Add Item Card)
  Widget _buildAddPeopleCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.1),
                        _accentColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    color: _accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add People',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add friends or family to split the bill with',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _showAddParticipantDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add People',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTab(bool isEmpty, double totalAmount) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Summary Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor.withOpacity(0.9), _primaryColor],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Total Bill Amount',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        PriceUtils.formatPrice(totalAmount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_items.length} items • ${_participants.length} participants',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Add Item Card
          _buildAddItemCard(),

          const SizedBox(height: 24),

          // Items List
          if (!isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Bill Items',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _items.length.toString(),
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final assignedCount = item.assignedTo.length;
                  final assignedNames = item.assignedTo
                      .map((id) {
                        final participant = _participants.firstWhere(
                          (p) => p.id == id,
                          orElse: () => Participant(
                            id: '',
                            name: 'Unknown',
                            phoneNumber: '',
                          ),
                        );
                        return participant.name;
                      })
                      .join(', ');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: _surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      elevation: 2,
                      child: Column(
                        children: [
                          // Item Header
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quantity Badge
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: assignedCount > 0
                                          ? [
                                              _accentColor.withOpacity(0.1),
                                              _accentColor.withOpacity(0.2),
                                            ]
                                          : [
                                              _warningColor.withOpacity(0.1),
                                              _warningColor.withOpacity(0.2),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${item.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: assignedCount > 0
                                              ? _accentColor
                                              : _warningColor,
                                        ),
                                      ),
                                      Text(
                                        'QTY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: assignedCount > 0
                                              ? _accentColor
                                              : _warningColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Item Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: _textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _bgColor,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '${PriceUtils.formatPrice(item.pricePerUnit)}/unit',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: _textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              PriceUtils.formatPrice(
                                                item.totalPrice,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _successColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Action Menu
                                PopupMenuButton<String>(
                                  icon: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _bgColor,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.more_vert_rounded,
                                      color: _textSecondary,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _editItem(index);
                                    } else if (value == 'delete') {
                                      _removeItem(index);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_rounded,
                                            color: _accentColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Edit Item'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.red.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Delete Item'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Assignment Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: assignedCount > 0
                                  ? _accentColor.withOpacity(0.05)
                                  : _warningColor.withOpacity(0.05),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: assignedCount > 0
                                        ? _accentColor.withOpacity(0.1)
                                        : _warningColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    assignedCount > 0
                                        ? Icons.group_rounded
                                        : Icons.warning_amber_rounded,
                                    size: 18,
                                    color: assignedCount > 0
                                        ? _accentColor
                                        : _warningColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignedCount > 0
                                            ? 'Assigned to $assignedCount participant${assignedCount > 1 ? 's' : ''}'
                                            : 'Not assigned',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: assignedCount > 0
                                              ? _accentColor
                                              : _warningColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (assignedCount > 0)
                                        const SizedBox(height: 2),
                                      if (assignedCount > 0)
                                        Text(
                                          assignedNames,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: assignedCount > 0
                                                ? _accentColor.withOpacity(0.8)
                                                : _warningColor.withOpacity(
                                                    0.8,
                                                  ),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            )
          else
            // Empty State
            Container(
              margin: const EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: _bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 56,
                      color: _borderColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Items Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Add bill items using the button above to start calculating',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textSecondary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Add Item Card
  Widget _buildAddItemCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _accentColor.withOpacity(0.1),
                        _accentColor.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    color: _accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add food or drink items from your bill',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Add Item',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// NEW: Add Participant Dialog
class AddParticipantDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final Color accentColor;
  final Color textSecondary;
  final Color primaryColor;
  final VoidCallback onSave;

  const AddParticipantDialog({
    Key? key,
    required this.nameController,
    required this.phoneController,
    required this.accentColor,
    required this.textSecondary,
    required this.primaryColor,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddParticipantDialogState createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends State<AddParticipantDialog> {
  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color(0xFFF5F7FA);
    final Color surfaceColor = Colors.white;
    final Color borderColor = const Color(0xFFE1E5E9);
    final Color textPrimary = const Color(0xFF0F172A);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Participant',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Name',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter full name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: bgColor,
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: widget.textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Phone Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '08XXX or +62XXX',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: widget.accentColor, width: 2),
                            ),
                            filled: true,
                            fillColor: bgColor,
                            prefixIcon: Icon(
                              Icons.phone_iphone_rounded,
                              color: widget.textSecondary,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Participant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (TutorialOverlay dan AddItemDialog tetap sama seperti sebelumnya)
// TUTORIAL OVERLAY (sama seperti sebelumnya)
class TutorialOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> tutorialSteps;
  final Color accentColor;
  final Color primaryColor;
  final VoidCallback onClose;

  const TutorialOverlay({
    Key? key,
    required this.tutorialSteps,
    required this.accentColor,
    required this.primaryColor,
    required this.onClose,
  }) : super(key: key);

  @override
  _TutorialOverlayState createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = const Color(0xFFF5F7FA);
    final Color surfaceColor = Colors.white;
    final Color textPrimary = const Color(0xFF0F172A);
    final Color textSecondary = const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'How to Use',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, color: textSecondary),
                  ),
                ),
              ],
            ),
          ),

          // Page View
          SizedBox(
            height: 320,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: widget.tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = widget.tutorialSteps[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.accentColor.withOpacity(0.1),
                              widget.accentColor.withOpacity(0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step['icon'] as IconData,
                          size: 48,
                          color: widget.accentColor,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        step['title'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step['description'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.tutorialSteps.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? widget.accentColor
                      : textSecondary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // Get Started Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == widget.tutorialSteps.length - 1
                      ? 'Get Started'
                      : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ADD ITEM DIALOG (sama seperti sebelumnya)
class AddItemDialog extends StatefulWidget {
  final List<Participant> participants;
  final Function(String, int, double, List<String>) onSave;
  final String? itemName;
  final int? quantity;
  final double? pricePerUnit;
  final List<String>? selectedParticipants;
  final Color accentColor;
  final Color textSecondary;
  final Color primaryColor;

  const AddItemDialog({
    Key? key,
    required this.participants,
    required this.onSave,
    this.itemName,
    this.quantity,
    this.pricePerUnit,
    this.selectedParticipants,
    required this.accentColor,
    required this.textSecondary,
    required this.primaryColor,
  }) : super(key: key);

  @override
  _AddItemDialogState createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  List<String> _selectedParticipants = [];

  @override
  void initState() {
    super.initState();
    if (widget.itemName != null) {
      _itemNameController.text = widget.itemName!;
    }
    if (widget.quantity != null) {
      _quantityController.text = widget.quantity!.toString();
    }
    if (widget.pricePerUnit != null) {
      _priceController.text = widget.pricePerUnit!.toStringAsFixed(0);
    }
    if (widget.selectedParticipants != null) {
      _selectedParticipants = List.from(widget.selectedParticipants!);
    }
  }

  double? _calculateTotal() {
    final quantity = int.tryParse(_quantityController.text);
    final pricePerUnit = double.tryParse(_priceController.text);

    if (quantity != null && pricePerUnit != null) {
      return quantity * pricePerUnit;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _calculateTotal();
    final Color bgColor = const Color(0xFFF5F7FA);
    final Color surfaceColor = Colors.white;
    final Color borderColor = const Color(0xFFE1E5E9);
    final Color textPrimary = const Color(0xFF0F172A);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.itemName == null ? 'Add New Item' : 'Edit Item',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Name
                    _buildFormField(
                      controller: _itemNameController,
                      label: 'Item Name',
                      icon: Icons.label_outline_rounded,
                      isRequired: true,
                    ),

                    const SizedBox(height: 20),

                    // Quantity and Price
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: _quantityController,
                            label: 'Quantity',
                            icon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildFormField(
                            controller: _priceController,
                            label: 'Price per Unit',
                            icon: Icons.attach_money_rounded,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                            onChanged: (value) => setState(() {}),
                          ),
                        ),
                      ],
                    ),

                    // Total Price Preview
                    if (totalPrice != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Price',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: widget.textSecondary,
                                  ),
                                ),
                                Text(
                                  PriceUtils.formatPrice(totalPrice),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: widget.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.calculate_rounded,
                                color: widget.accentColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Assign to Participants
                    if (widget.participants.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Assign to Participants',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _selectedParticipants.length.toString(),
                                  style: TextStyle(
                                    color: widget.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Select who shares this item',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: widget.participants.map((participant) {
                              final isSelected = _selectedParticipants.contains(
                                participant.id,
                              );

                              return ChoiceChip(
                                label: Text(participant.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedParticipants.add(participant.id);
                                    } else {
                                      _selectedParticipants.remove(
                                        participant.id,
                                      );
                                    }
                                  });
                                },
                                backgroundColor: surfaceColor,
                                selectedColor: widget.accentColor.withOpacity(
                                  0.15,
                                ),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? widget.accentColor
                                      : textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                                avatar: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: Colors.grey[200],
                                        textDirection: TextDirection.ltr,
                                        size: 20,
                                      )
                                    : Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            participant.name
                                                .substring(0, 1)
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: widget.textSecondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? widget.accentColor.withOpacity(0.3)
                                        : borderColor,
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Colors.orange.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Add participants first before assigning items',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(top: BorderSide(color: borderColor, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: borderColor),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final itemName = _itemNameController.text.trim();
                        final quantity = int.tryParse(
                          _quantityController.text.trim(),
                        );
                        final pricePerUnit = double.tryParse(
                          _priceController.text.trim(),
                        );

                        if (itemName.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Item name is required'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        if (quantity == null || quantity <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Valid quantity is required'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        if (pricePerUnit == null || pricePerUnit <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Valid price per unit is required',
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                          return;
                        }

                        widget.onSave(
                          itemName,
                          quantity,
                          pricePerUnit,
                          _selectedParticipants,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE1E5E9)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE1E5E9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.accentColor, width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            prefixIcon: Icon(icon, color: widget.textSecondary),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}