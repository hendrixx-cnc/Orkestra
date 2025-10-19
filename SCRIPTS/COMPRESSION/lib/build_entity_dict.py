#!/usr/bin/env python3
"""
HACS Entity Dictionary Builder
Extracts entities (dates, emails, URLs, IPs, names) from input text
"""
import re
import json
import sys

def extract_entities(text):
    entities = {}
    
    # Date patterns (ISO format)
    dates = re.findall(r'\b\d{4}-\d{2}-\d{2}\b', text)
    for date in set(dates):
        entities[f"D:{date.replace('-', '')}"] = {
            "original": date,
            "type": "date",
            "frequency": dates.count(date),
            "count": dates.count(date)
        }
    
    # Email addresses
    emails = re.findall(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', text)
    for email in set(emails):
        # Use domain as ID
        parts = email.split('@')
        domain_parts = parts[1].split('.')
        user_part = parts[0][:3]
        entity_id_str = f"E:{user_part}{domain_parts[0][:4]}"
        entities[entity_id_str] = {
            "original": email,
            "type": "email",
            "frequency": emails.count(email),
            "count": emails.count(email)
        }
    
    # URLs
    urls = re.findall(r'https?://[^\s<>"{}|\\^`\[\]]+', text)
    for url in set(urls):
        domain = re.search(r'://([^/]+)', url)
        if domain:
            domain_name = domain.group(1).replace('www.', '').split('.')[0]
            entity_id_str = f"U:{domain_name[:6]}"
            entities[entity_id_str] = {
                "original": url,
                "type": "url",
                "frequency": urls.count(url),
                "count": urls.count(url)
            }
    
    # IP addresses
    ips = re.findall(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', text)
    for ip in set(ips):
        parts = ip.split('.')
        entity_id_str = f"IP:{parts[0]}{parts[3]}"
        entities[entity_id_str] = {
            "original": ip,
            "type": "ip",
            "frequency": ips.count(ip),
            "count": ips.count(ip)
        }
    
    return entities

if __name__ == "__main__":
    input_file = sys.argv[1] if len(sys.argv) > 1 else '/dev/stdin'
    
    with open(input_file, 'r') as f:
        text = f.read()
    
    entities = extract_entities(text)
    
    # Output as JSON
    output = {
        "type": "entity_dictionary",
        "version": "1.0",
        "count": len(entities),
        "entries": entities
    }
    
    print(json.dumps(output, indent=2))
