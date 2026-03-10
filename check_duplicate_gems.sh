#!/bin/bash
echo "🔍 GEMFILE DUPLICATE CHECKER"
echo "=============================="

# Find duplicate gems in Gemfile
echo "Checking Gemfile for duplicates..."
awk '/^gem / {gems[$2]++} END {for (gem in gems) if (gems[gem] > 1) print "❌ DUPLICATE: " gem}' Gemfile

# Check Gemfile.lock for issues
echo -e "\nChecking Gemfile.lock..."
if grep -q "Duplicate dependencies" Gemfile.lock; then
  echo "❌ Gemfile.lock has duplicate dependencies"
else
  echo "✅ Gemfile.lock clean"
fi

# Count gem occurrences
echo -e "\n📊 Gem counts (top duplicates):"
grep "^gem " Gemfile | cut -d"'" -f2 | sort | uniq -c | sort -nr | head -10

# Auto-fix common duplicates
echo -e "\n🛠️ Auto-fixing common duplicates..."
if grep -q "gem 'stripe'" Gemfile; then
  echo "✅ Stripe gem detected (checking duplicates...)"
  count=$(grep -c "gem 'stripe" Gemfile)
  if [ $count -gt 1 ]; then
    echo "⚠️  $count stripe gems found - keeping newest version"
    sed -i '/gem '\''stripe'\''/N;/\n.*gem '\''stripe'\''/D' Gemfile
  fi
fi

echo -e "\n✅ Run: bundle install"
