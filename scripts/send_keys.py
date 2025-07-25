#!/usr/bin/env python3
"""
SSH Key Email Script for AWS EC2 User Provisioning

This script sends SSH private keys to users via email after they have been
provisioned on EC2 instances. It reads user information and generated keys
from Terraform outputs and sends personalized emails to each user.

Requirements:
- Python 3.6+
- smtplib (built-in)
- yaml (pip install pyyaml)
- json (built-in)
- os (built-in)
- sys (built-in)
"""

import smtplib
import yaml
import json
import os
import sys
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from datetime import datetime
import argparse

class SSHKeyEmailer:
    def __init__(self, smtp_host, smtp_user, smtp_pass, smtp_port=587):
        """
        Initialize the SSH key emailer with SMTP settings.
        
        Args:
            smtp_host (str): SMTP server hostname
            smtp_user (str): SMTP username
            smtp_pass (str): SMTP password
            smtp_port (int): SMTP port (default: 587 for TLS)
        """
        self.smtp_host = smtp_host
        self.smtp_user = smtp_user
        self.smtp_pass = smtp_pass
        self.smtp_port = smtp_port
        
    def load_users(self, users_file):
        """
        Load user information from YAML file.
        
        Args:
            users_file (str): Path to users.yaml file
            
        Returns:
            dict: User information
        """
        try:
            with open(users_file, 'r') as file:
                data = yaml.safe_load(file)
                return {user['username']: user for user in data['users']}
        except FileNotFoundError:
            print(f"Error: Users file '{users_file}' not found.")
            sys.exit(1)
        except yaml.YAMLError as e:
            print(f"Error parsing YAML file: {e}")
            sys.exit(1)
    
    def load_terraform_output(self, terraform_dir):
        """
        Load Terraform output containing user keys.
        
        Args:
            terraform_dir (str): Path to terraform directory
            
        Returns:
            dict: Terraform output data
        """
        try:
            # Try to read from terraform output file
            output_file = os.path.join(terraform_dir, 'terraform_output.json')
            if os.path.exists(output_file):
                with open(output_file, 'r') as file:
                    data = json.load(file)
                    # Extract user_private_keys from the output
                    if 'user_private_keys' in data:
                        return data['user_private_keys']['value']
                    else:
                        print("Warning: No user_private_keys found in terraform output")
            
            # If no output file or no user keys, try to read from keys directory
            keys_dir = os.path.join(terraform_dir, 'keys')
            if not os.path.exists(keys_dir):
                print(f"Error: Keys directory '{keys_dir}' not found.")
                print("Please run 'terraform apply' first to generate SSH keys.")
                sys.exit(1)
            
            # Read keys from files
            keys_data = {}
            for filename in os.listdir(keys_dir):
                if filename.endswith('_private_key.pem'):
                    username = filename.replace('_private_key.pem', '')
                    key_file = os.path.join(keys_dir, filename)
                    with open(key_file, 'r') as file:
                        private_key = file.read()
                    
                    # Try to read corresponding public key
                    pub_key_file = os.path.join(keys_dir, f"{username}_public_key.pub")
                    public_key = ""
                    if os.path.exists(pub_key_file):
                        with open(pub_key_file, 'r') as file:
                            public_key = file.read()
                    
                    keys_data[username] = {
                        'private_key': private_key,
                        'public_key': public_key
                    }
            
            if not keys_data:
                print("Error: No SSH keys found in keys directory.")
                print("Please run 'terraform apply' first to generate SSH keys.")
                sys.exit(1)
                
            return keys_data
            
        except Exception as e:
            print(f"Error loading Terraform output: {e}")
            sys.exit(1)
    
    def create_email_content(self, username, user_info, private_key, instances_info=None):
        """
        Create email content for a user.
        
        Args:
            username (str): Username
            user_info (dict): User information
            private_key (str): User's private SSH key
            instances_info (dict): Information about EC2 instances
            
        Returns:
            tuple: (subject, html_content, text_content)
        """
        subject = f"Your SSH Access Credentials - {username}"
        
        # Create HTML content
        html_content = f"""
        <html>
        <head>
            <style>
                body {{ font-family: Arial, sans-serif; line-height: 1.6; color: #333; }}
                .container {{ max-width: 600px; margin: 0 auto; padding: 20px; }}
                .header {{ background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 20px; }}
                .key-section {{ background-color: #f1f3f4; padding: 15px; border-radius: 5px; margin: 15px 0; }}
                .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 15px 0; }}
                .code {{ font-family: 'Courier New', monospace; background-color: #f8f9fa; padding: 10px; border-radius: 3px; }}
                .button {{ display: inline-block; background-color: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h2>🔐 Your SSH Access Credentials</h2>
                    <p>Hello {user_info.get('full_name', username)},</p>
                    <p>Your user account has been successfully provisioned on our AWS EC2 instances.</p>
                </div>
                
                <h3>📋 Account Information</h3>
                <ul>
                    <li><strong>Username:</strong> {username}</li>
                    <li><strong>Email:</strong> {user_info.get('email', 'N/A')}</li>
                    <li><strong>Provisioned:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</li>
                </ul>
                
                <h3>🔑 Your SSH Private Key</h3>
                <div class="key-section">
                    <p><strong>Important:</strong> Keep this private key secure and never share it with anyone.</p>
                    <div class="code">{private_key}</div>
                </div>
                
                <h3>📝 How to Use Your SSH Key</h3>
                <ol>
                    <li>Save the private key above to a file (e.g., <code>~/.ssh/{username}_key.pem</code>)</li>
                    <li>Set proper permissions: <code>chmod 600 ~/.ssh/{username}_key.pem</code></li>
                    <li>Connect to instances using: <code>ssh -i ~/.ssh/{username}_key.pem {username}@INSTANCE_IP</code></li>
                </ol>
                
                <div class="warning">
                    <h4>⚠️ Security Notice</h4>
                    <ul>
                        <li>Never share your private key with anyone</li>
                        <li>Store the key securely on your local machine</li>
                        <li>Use a passphrase for additional security if needed</li>
                        <li>Report any security concerns immediately</li>
                    </ul>
                </div>
                
                <h3>🆘 Need Help?</h3>
                <p>If you have any questions or need assistance, please contact your system administrator.</p>
                
                <hr>
                <p><em>This is an automated message. Please do not reply to this email.</em></p>
            </div>
        </body>
        </html>
        """
        
        # Create plain text content
        text_content = f"""
Your SSH Access Credentials - {username}

Hello {user_info.get('full_name', username)},

Your user account has been successfully provisioned on our AWS EC2 instances.

Account Information:
- Username: {username}
- Email: {user_info.get('email', 'N/A')}
- Provisioned: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}

Your SSH Private Key:
{private_key}

How to Use Your SSH Key:
1. Save the private key above to a file (e.g., ~/.ssh/{username}_key.pem)
2. Set proper permissions: chmod 600 ~/.ssh/{username}_key.pem
3. Connect to instances using: ssh -i ~/.ssh/{username}_key.pem {username}@INSTANCE_IP

Security Notice:
- Never share your private key with anyone
- Store the key securely on your local machine
- Use a passphrase for additional security if needed
- Report any security concerns immediately

Need Help?
If you have any questions or need assistance, please contact your system administrator.

---
This is an automated message. Please do not reply to this email.
        """
        
        return subject, html_content, text_content
    
    def send_email(self, to_email, subject, html_content, text_content, private_key=None):
        """
        Send email to a user.
        
        Args:
            to_email (str): Recipient email address
            subject (str): Email subject
            html_content (str): HTML email content
            text_content (str): Plain text email content
            private_key (str): Private key to attach (optional)
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = self.smtp_user
            msg['To'] = to_email
            msg['Subject'] = subject
            
            # Attach text and HTML parts
            text_part = MIMEText(text_content, 'plain')
            html_part = MIMEText(html_content, 'html')
            msg.attach(text_part)
            msg.attach(html_part)
            
            # Attach private key if provided
            if private_key:
                key_attachment = MIMEApplication(private_key, _subtype='pem')
                key_attachment.add_header('Content-Disposition', 'attachment', 
                                        filename=f'ssh_private_key.pem')
                msg.attach(key_attachment)
            
            # Send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                server.starttls()
                server.login(self.smtp_user, self.smtp_pass)
                server.send_message(msg)
            
            return True
            
        except Exception as e:
            print(f"Error sending email to {to_email}: {e}")
            return False
    
    def send_keys_to_users(self, users_file, terraform_dir, dry_run=False):
        """
        Send SSH keys to all users.
        
        Args:
            users_file (str): Path to users.yaml file
            terraform_dir (str): Path to terraform directory
            dry_run (bool): If True, don't actually send emails
            
        Returns:
            dict: Results of email sending
        """
        print("Loading user information...")
        users = self.load_users(users_file)
        
        print("Loading Terraform output...")
        keys_data = self.load_terraform_output(terraform_dir)
        
        results = {
            'total_users': len(users),
            'emails_sent': 0,
            'emails_failed': 0,
            'details': []
        }
        
        print(f"Found {len(users)} users to process")
        
        for username, user_info in users.items():
            if username not in keys_data:
                print(f"Warning: No SSH key found for user {username}")
                results['emails_failed'] += 1
                results['details'].append({
                    'username': username,
                    'email': user_info.get('email'),
                    'status': 'failed',
                    'reason': 'No SSH key found'
                })
                continue
            
            email = user_info.get('email')
            if not email:
                print(f"Warning: No email address for user {username}")
                results['emails_failed'] += 1
                results['details'].append({
                    'username': username,
                    'email': None,
                    'status': 'failed',
                    'reason': 'No email address'
                })
                continue
            
            print(f"Processing user: {username} ({email})")
            
            if dry_run:
                print(f"  [DRY RUN] Would send email to {email}")
                results['emails_sent'] += 1
                results['details'].append({
                    'username': username,
                    'email': email,
                    'status': 'dry_run',
                    'reason': 'Dry run mode'
                })
                continue
            
            # Create email content
            subject, html_content, text_content = self.create_email_content(
                username, user_info, keys_data[username]['private_key']
            )
            
            # Send email
            success = self.send_email(email, subject, html_content, text_content)
            
            if success:
                print(f"  ✓ Email sent successfully to {email}")
                results['emails_sent'] += 1
                results['details'].append({
                    'username': username,
                    'email': email,
                    'status': 'success'
                })
            else:
                print(f"  ✗ Failed to send email to {email}")
                results['emails_failed'] += 1
                results['details'].append({
                    'username': username,
                    'email': email,
                    'status': 'failed',
                    'reason': 'SMTP error'
                })
        
        return results

def main():
    """Main function to run the SSH key emailer."""
    parser = argparse.ArgumentParser(description='Send SSH keys to users via email')
    parser.add_argument('--users-file', default='../users.yaml', 
                       help='Path to users.yaml file (default: ../users.yaml)')
    parser.add_argument('--terraform-dir', default='../terraform', 
                       help='Path to terraform directory (default: ../terraform)')
    parser.add_argument('--smtp-host', required=True, 
                       help='SMTP server hostname')
    parser.add_argument('--smtp-user', required=True, 
                       help='SMTP username')
    parser.add_argument('--smtp-pass', required=True, 
                       help='SMTP password')
    parser.add_argument('--smtp-port', type=int, default=587, 
                       help='SMTP port (default: 587)')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Dry run mode (don\'t actually send emails)')
    
    args = parser.parse_args()
    
    # Create emailer instance
    emailer = SSHKeyEmailer(args.smtp_host, args.smtp_user, args.smtp_pass, args.smtp_port)
    
    # Send keys to users
    results = emailer.send_keys_to_users(args.users_file, args.terraform_dir, args.dry_run)
    
    # Print summary
    print("\n" + "="*50)
    print("EMAIL SENDING SUMMARY")
    print("="*50)
    print(f"Total users: {results['total_users']}")
    print(f"Emails sent: {results['emails_sent']}")
    print(f"Emails failed: {results['emails_failed']}")
    
    if results['emails_failed'] > 0:
        print("\nFailed emails:")
        for detail in results['details']:
            if detail['status'] == 'failed':
                print(f"  - {detail['username']}: {detail.get('reason', 'Unknown error')}")
    
    if args.dry_run:
        print("\nNote: This was a dry run - no emails were actually sent.")
    
    print("="*50)

if __name__ == "__main__":
    main() 