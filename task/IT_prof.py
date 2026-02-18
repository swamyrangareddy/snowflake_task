import requests
import csv

search_url = "https://api.github.com/search/users?q=followers:>1000&per_page=5"
search_data = requests.get(search_url).json()

users = search_data.get("items", [])

results = []

for user in users:
    username = user["login"]
    profile_api = f"https://api.github.com/users/{username}"
    
    profile = requests.get(profile_api).json()

    results.append([
        profile.get("name"),
        username,
        profile.get("company"),
        profile.get("location"),
        profile.get("followers"),
        profile.get("html_url"),
        profile.get("bio")
    ])

# Save CSV
with open("github_full_data.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow([
        "Name", "Username", "Company", "Location",
        "Followers", "Profile", "Bio"
    ])
    writer.writerows(results)

print("✅ Full GitHub data saved!")
