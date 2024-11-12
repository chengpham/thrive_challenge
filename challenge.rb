require 'json'

# Load data from JSON files
def load_data(file)
    JSON.parse(File.read(file), symbolize_names: true)
end

# Write data to output file
def write_output(data, filename)
    File.open(filename, 'w') { |file| file.write(data) }
end

# Format user info
def format_user_info(user, old_tokens, new_tokens)
    info = "\t#{ user[:last_name] }, #{ user[:first_name] }, #{ user[:email] }\n"
    info << "\t  Previous Token Balance, #{ old_tokens }\n"
    info << "\t  New Token Balance #{ new_tokens }\n"
    return info
end
  
# Format company info
def format_company_info(company_id, company_name, users_emailed, users_not_emailed, total_top_up)
    info = "Company Id: #{ company_id }\n"
    info << "Company Name: #{ company_name }\n"
    info << "Users Emailed:\n"
    info << users_emailed.join || ""
    info << "Users Not Emailed:\n"
    info << users_not_emailed.join || ""
    info << "\tTotal amount of top ups for #{ company_name }: #{ total_top_up }\n\n"
    return info
end

# Process users and companies to generate output
def process_data(users, companies)
    result = ""

    # Sort companies by company id
    companies.sort_by! { |company| company[:id] }

    companies.each do |company|
        company_id = company[:id]
        company_name = company[:name]
        company_top_up = company[:top_up]
        company_email_status = company[:email_status]

        # Filter by active users in the company
        users_for_company = users.select { |user| user[:company_id] == company_id && user[:active_status] }

        # Skip if there are no active users for the company
        next if users_for_company.empty?

        users_emailed = []
        users_not_emailed = []
        total_top_up = 0

        # Process users for the company
        users_for_company.sort_by { |user| user[:last_name] }.each do |user|
            old_tokens = user[:tokens]
            new_tokens = old_tokens + company_top_up
            user[:tokens] = new_tokens
            total_top_up += company_top_up

            # Check email status
            if user[:email_status] && company_email_status
                users_emailed << format_user_info(user, old_tokens, new_tokens)
            else
                users_not_emailed << format_user_info(user, old_tokens, new_tokens)
            end
        end

        # Append company information to the result string
        result << format_company_info(company_id, company_name, users_emailed, users_not_emailed, total_top_up)
    end

    return result
end

# Main execution starts here
begin
  users = load_data('users.json')
  companies = load_data('companies.json')
  output_data = process_data(users, companies)
  write_output(output_data, 'output.txt')
  puts "Output generated in output.txt"
rescue StandardError => error
  puts "ERROR: #{ error.message }"
end
