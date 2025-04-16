require 'net/http'
require 'uri'
require 'json'
require 'securerandom'

def generate_random_username(length = 8)
  characters = ('a'..'z').to_a + ('0'..'9').to_a + ['.']
  loop do
    username = (1..length).map { characters.sample }.join
    return username unless username.start_with?('.') || username.end_with?('.') || username.include?('..')
  end
end

def generate_wallet_and_key
  hex_chars = ('0'..'9').to_a + ('a'..'f').to_a
  private_key = (1..64).map { hex_chars.sample }.join
  wallet = '0x' + (1..40).map { hex_chars.sample }.join
  [wallet, private_key]
end

def save_to_json(data, filename = 'accounts.json')
  begin
    existing_data = File.exist?(filename) ? JSON.parse(File.read(filename)) : []
    existing_data += data
    File.write(filename, JSON.pretty_generate(existing_data))
    puts "✓ Data saved to #{filename}"
  rescue StandardError => e
    puts "✗ Error saving to JSON: #{e.message}"
  end
end

def join_waitlist(username, wallet)
  uri = URI.parse('https://glider.fi/api/waitlist')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.path)
  request['accept'] = '*/*'
  request['content-type'] = 'text/plain;charset=UTF-8'
  request['origin'] = 'https://glider.fi'
  request['referer'] = 'https://glider.fi/'
  request['sec-ch-ua'] = '"Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"'
  request['sec-ch-ua-mobile'] = '?0'
  request['sec-ch-ua-platform'] = '"Windows"'
  request['user-agent'] = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36'
  request.body = { username: username, wallet: wallet }.to_json

  begin
    response = http.request(request)
    if response.code == '200'
      puts "✓ Successfully joined waitlist for #{username}"
      return JSON.parse(response.body), true
    elsif response.code == '500'
      puts "✗ Server error for #{username}, skipping save"
      return nil, false
    else
      puts "✗ Failed for #{username}: Status code #{response.code}"
      return nil, false
    end
  rescue StandardError => e
    puts "✗ Request failed for #{username}: #{e.message}"
    return nil, false
  end
end

def main
  puts <<~BANNER
  ╔══════════════════════════════════════════════╗
  ║       🌟 GLIDER.FI - Waitlist Automation     ║
  ║ Automate Glider.fi waitlist registrations!   ║
  ║  Developed by: https://t.me/sentineldiscus   ║
  ╚══════════════════════════════════════════════╝
  BANNER

  print 'Enter the number of accounts to generate: '
  begin
    num_accounts = Integer(gets.chomp)
    if num_accounts <= 0
      puts '✗ Please enter a positive number.'
      return
    end
  rescue ArgumentError
    puts '✗ Please enter a valid number.'
    return
  end

  delay = 2
  accounts = []

  num_accounts.times do |i|
    puts "\nGenerating account #{i + 1}/#{num_accounts}"

    username = generate_random_username
    puts "Generated username: #{username}"

    wallet, private_key = generate_wallet_and_key
    puts "Generated wallet: #{wallet}"
    puts "Generated private key: #{private_key}"

    account_data = {
      'username' => username,
      'wallet' => wallet,
      'private_key' => private_key
    }

    result, success = join_waitlist(username, wallet)
    accounts << account_data if success

    if i < num_accounts - 1
      puts "Waiting #{delay} seconds before next attempt..."
      sleep(delay)
    end
  end

  save_to_json(accounts) unless accounts.empty?
end

main if __FILE__ == $PROGRAM_NAME
