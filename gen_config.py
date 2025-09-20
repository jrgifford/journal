#!/usr/bin/python
# -*- coding: utf-8 -*-
"""
Q4 2025 Configuration for Journal Generation
Complete configuration with all required attributes for Docker compatibility
"""
import locale
import gen_events as events

# Year and quarter configuration for Q4 2025
year = 2025
quarter = 4
start_month = 10
end_month = 12

# True if the week starts on Monday (European convention), False if it starts on Sunday.
week_starts_on_Monday = True

# Locale -- try to set en_GB.utf-8, fall back to available locales
try:
    locale.setlocale(locale.LC_ALL, 'en_GB.utf-8')      # Great Britain
except locale.Error:
    try:
        locale.setlocale(locale.LC_ALL, 'C.UTF-8')      # Fallback UTF-8
    except locale.Error:
        locale.setlocale(locale.LC_ALL, 'C')           # Final fallback

# Define "Week" and "Notes" words, being used in the Weekly Planner
Week_locale = 'Week'
HowGo_locale = 'How did it go?'
Notes_locale = 'Notes'
Week_Goals_locale = 'Week Goals'
Physical_Activity_locale = 'Exercise'

# Q4 2025 holidays and events
# October 2025
events.add_event(year, 10, 31, "Halloween", False)

# November 2025
events.add_event(year, 11, 11, "Remembrance Day", True)
events.add_event(year, 11, 27, "Thanksgiving (US)", True)

# December 2025
events.add_event(year, 12, 24, "Christmas Eve", True)
events.add_event(year, 12, 25, "Christmas Day", True)
events.add_event(year, 12, 26, "Boxing Day", True)
events.add_event(year, 12, 31, "New Year's Eve", False)

# New Year's Day for next year
events.add_event(year + 1, 1, 1, "New Year's Day", True)

# Q4-specific settings
output_filename = 'journal-2025-q4.pdf'

print(f"Q4 2025 configuration loaded: {year} Q{quarter} ({start_month}-{end_month})")
print(f"Locale: {locale.getlocale()}")
print(f"Week starts Monday: {week_starts_on_Monday}")