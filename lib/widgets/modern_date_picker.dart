import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_styles.dart';

class ModernDatePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime startDate, DateTime endDate) onDateRangeSelected;

  const ModernDatePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onDateRangeSelected,
  });

  @override
  State<ModernDatePicker> createState() => _ModernDatePickerState();
}

class _ModernDatePickerState extends State<ModernDatePicker>
    with TickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _currentMonth = DateTime.now();
  PageController _pageController = PageController();
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectDate(DateTime date) {
    HapticFeedback.lightImpact(); // Add haptic feedback
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Start a new selection
        _startDate = date;
        _endDate = null;
      } else if (_startDate != null && _endDate == null) {
        // Complete the range
        if (date.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = date;
        } else {
          _endDate = date;
        }
      }
    });
  }

  List<DateTime> _getDaysInMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = <DateTime>[];

    // Add empty days for proper alignment
    final firstWeekday = firstDay.weekday;
    for (int i = 1; i < firstWeekday; i++) {
      daysInMonth.add(firstDay.subtract(Duration(days: firstWeekday - i)));
    }

    // Add actual days of the month
    for (int i = 0; i < lastDay.day; i++) {
      daysInMonth.add(firstDay.add(Duration(days: i)));
    }

    return daysInMonth;
  }

  bool _isSelected(DateTime date) {
    if (_startDate != null && _isSameDay(date, _startDate!)) return true;
    if (_endDate != null && _isSameDay(date, _endDate!)) return true;
    return false;
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    return date.isAfter(_startDate!) && date.isBefore(_endDate!);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return _isSameDay(date, today);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildDateDisplay(),
                _buildCalendar(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.primaryColor,
            AppStyles.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Trip Dates',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _getHeaderSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  String _getHeaderSubtitle() {
    if (_startDate == null) {
      return 'Choose your check-in date';
    } else if (_endDate == null) {
      return 'Choose your check-out date';
    } else {
      final nights = _endDate!.difference(_startDate!).inDays;
      return '$nights night${nights != 1 ? 's' : ''} selected';
    }
  }

  Widget _buildDateDisplay() {
    return Container(
      padding: const EdgeInsets.all(14), // Reduced from 16 to 14
      child: Row(
        children: [
          Expanded(
            child: _buildDateCard(
              'CHECK-IN',
              _startDate,
              Icons.flight_land_rounded,
              AppStyles.primaryColor,
            ),
          ),
          Container(
            width: 28, // Reduced from 30 to 28
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 6), // Reduced from 8 to 6
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppStyles.primaryColor.withOpacity(0.3),
                  AppStyles.primaryColor,
                  AppStyles.primaryColor.withOpacity(0.3),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildDateCard(
              'CHECK-OUT',
              _endDate,
              Icons.flight_takeoff_rounded,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard(String label, DateTime? date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10), // Reduced from 12 to 10
      decoration: BoxDecoration(
        color: date != null ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: date != null ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added to minimize space
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the content
            children: [
              Icon(
                icon,
                size: 13, // Reduced from 14 to 13
                color: date != null ? color : Colors.grey,
              ),
              const SizedBox(width: 3), // Reduced from 4 to 3
              Flexible( // Added Flexible to prevent overflow
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10, // Reduced from 11 to 10
                    fontWeight: FontWeight.w600,
                    color: date != null ? color : Colors.grey,
                    letterSpacing: 0.2, // Reduced from 0.3 to 0.2
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5), // Reduced from 6 to 5
          Text(
            date != null
                ? '${date.day}'
                : '-',
            style: TextStyle(
              fontSize: 21, // Reduced from 22 to 21
              fontWeight: FontWeight.bold,
              color: date != null ? color : Colors.grey,
            ),
          ),
          Text(
            date != null
                ? _getMonthName(date.month)
                : 'Select',
            style: TextStyle(
              fontSize: 12, // Reduced from 13 to 12
              color: date != null ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16), // Reduced from 20 to 16
      child: Column(
        children: [
          _buildMonthHeader(),
          const SizedBox(height: 16),
          _buildWeekDays(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
          icon: Icon(
            Icons.chevron_left_rounded,
            color: AppStyles.primaryColor,
          ),
        ),
        Text(
          '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
            });
          },
          icon: Icon(
            Icons.chevron_right_rounded,
            color: AppStyles.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: weekDays.map((day) => Expanded(
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final days = _getDaysInMonth(_currentMonth);
    return Container(
      height: 240,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final date = days[index];
          final isCurrentMonth = date.month == _currentMonth.month;
          final isSelected = _isSelected(date);
          final isInRange = _isInRange(date);
          final isToday = _isToday(date);
          final isPast = date.isBefore(DateTime.now()) && !_isToday(date);

          return GestureDetector(
            onTap: isPast || !isCurrentMonth ? null : () => _selectDate(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppStyles.primaryColor
                    : isInRange
                        ? AppStyles.primaryColor.withOpacity(0.2)
                        : isToday
                            ? AppStyles.primaryColor.withOpacity(0.1)
                            : null,
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected
                    ? Border.all(color: AppStyles.primaryColor, width: 1)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppStyles.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    color: !isCurrentMonth
                        ? Colors.grey[300]
                        : isPast
                            ? Colors.grey[400]
                            : isSelected
                                ? Colors.white
                                : isInRange
                                    ? AppStyles.primaryColor
                                    : isToday
                                        ? AppStyles.primaryColor
                                        : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16), // Reduced from 20 to 16
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Clear',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _startDate != null && _endDate != null
                  ? () async {
                      HapticFeedback.mediumImpact();
                      
                      // Animate out before calling the callback and closing
                      await _slideController.reverse();
                      
                      if (mounted) {
                        // Close the dialog first
                        Navigator.of(context).pop();
                        
                        // Then call the callback
                        widget.onDateRangeSelected(_startDate!, _endDate!);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Confirm Dates',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
