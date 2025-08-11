#!/usr/bin/env python3
"""
SSH Key Email Script for AWS EC2 User Provisioning

This script sends SSH private keys to users via email after they have been
provisioned on EC2 instances. It reads user information and generated keys
from the keys directory and sends personalized emails to each user.

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
    def __init__(self, smtp_host, smtp_user=None, smtp_pass=None, smtp_port=25):
        """
        Initialize the SSH key emailer with SMTP settings.
        
        Args:
            smtp_host (str): SMTP server hostname
            smtp_user (str): SMTP username (optional for port 25)
            smtp_pass (str): SMTP password (optional for port 25)
            smtp_port (int): SMTP port (default: 25 for no-auth)
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
    
    def load_keys_from_directory(self, keys_dir):
        """
        Load SSH keys from the keys directory.
        
        Args:
            keys_dir (str): Path to keys directory
            
        Returns:
            dict: Dictionary of username -> private_key mapping
        """
        try:
            if not os.path.exists(keys_dir):
                print(f"Error: Keys directory '{keys_dir}' not found.")
                print("Please ensure SSH keys have been generated.")
                sys.exit(1)
            
            keys_data = {}
            print(f"Scanning keys directory: {keys_dir}")
            
            for filename in os.listdir(keys_dir):
                if filename.endswith('_private_key'):
                    username = filename.replace('_private_key', '')
                    key_file = os.path.join(keys_dir, filename)
                    
                    print(f"Found private key for user: {username}")
                    
                    try:
                        with open(key_file, 'r') as f:
                            private_key = f.read()
                            keys_data[username] = private_key
                            print(f"✅ Loaded private key for {username}")
                    except Exception as e:
                        print(f"❌ Error reading key file {key_file}: {e}")
                        continue
            
            if not keys_data:
                print("❌ No private keys found in keys directory")
                sys.exit(1)
            
            print(f"✅ Loaded {len(keys_data)} private keys")
            return keys_data
            
        except Exception as e:
            print(f"Error loading keys: {e}")
            sys.exit(1)
    
    def create_email_content(self, username, user_info, private_key, test_email=None):
        """
        Create email content for SSH key delivery.
        
        Args:
            username (str): Username
            user_info (dict): User information from YAML
            private_key (str): Private key content
            test_email (str): Test email address (optional)
            
        Returns:
            tuple: (html_content, text_content)
        """
        # Use test email if provided, otherwise use user's email
        recipient_email = test_email if test_email else user_info['email']
        
        # Create HTML content
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>SSH Key for EC2 Access - {username}</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                .header {{ background-color: #f8f9fa; padding: 20px; border-radius: 5px; }}
                .content {{ margin: 20px 0; }}
                .key-section {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; color: #6c757d; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>🔑 SSH Key for EC2 Access</h2>
                <p><strong>Username:</strong> {username}</p>
                <p><strong>Full Name:</strong> {user_info['full_name']}</p>
                <p><strong>Generated:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
            </div>
            
            <div class="content">
                <h3>Your SSH Private Key</h3>
                <p>Your SSH private key has been generated and is attached to this email. Use this key to access your EC2 instance.</p>
                
                <div class="key-section">
                    <h4>Key Details:</h4>
                    <ul>
                        <li><strong>Key Type:</strong> RSA 4096-bit</li>
                        <li><strong>Format:</strong> OpenSSH compatible</li>
                        <li><strong>Usage:</strong> EC2 instance access</li>
                    </ul>
                </div>
                
                <div class="warning">
                    <h4>⚠️ Security Important:</h4>
                    <ul>
                        <li>Keep this private key secure and never share it</li>
                        <li>Store it in a safe location (e.g., ~/.ssh/ directory)</li>
                        <li>Set proper permissions: chmod 600 your_key_file</li>
                        <li>Never commit private keys to version control</li>
                    </ul>
                </div>
                
                <h3>How to Use</h3>
                <ol>
                    <li>Save the attached private key to your local machine</li>
                    <li>Set proper permissions: <code>chmod 600 your_key_file</code></li>
                    <li>Connect to EC2: <code>ssh -i your_key_file {username}@EC2_IP_ADDRESS</code></li>
                </ol>
            </div>
            
            <div class="footer">
                <p><em>This is an automated message from the AWS EC2 User Provisioning System.</em></p>
                <p><em>If you have any questions, please contact your system administrator.</em></p>
            </div>
        </body>
        </html>
        """
        
        # Create plain text content
        text_content = f"""
SSH Key for EC2 Access - {username}

Username: {username}
Full Name: {user_info['full_name']}
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}

Your SSH private key has been generated and is attached to this email. 
Use this key to access your EC2 instance.

Key Details:
- Key Type: RSA 4096-bit
- Format: OpenSSH compatible
- Usage: EC2 instance access

Security Important:
- Keep this private key secure and never share it
- Store it in a safe location (e.g., ~/.ssh/ directory)
- Set proper permissions: chmod 600 your_key_file
- Never commit private keys to version control

How to Use:
1. Save the attached private key to your local machine
2. Set proper permissions: chmod 600 your_key_file
3. Connect to EC2: ssh -i your_key_file {username}@EC2_IP_ADDRESS

This is an automated message from the AWS EC2 User Provisioning System.
If you have any questions, please contact your system administrator.
        """
        
        return html_content, text_content
    
    def send_email(self, to_email, subject, html_content, text_content, private_key=None, username=None):
        """
        Send email with SSH key attachment.
        
        Args:
            to_email (str): Recipient email address
            subject (str): Email subject
            html_content (str): HTML email content
            text_content (str): Plain text email content
            private_key (str): Private key content to attach
            username (str): Username for filename
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['From'] = f"EC2-Provisioning <noreply@{self.smtp_host}>"
            msg['To'] = to_email
            msg['Subject'] = subject
            
            # Add text and HTML parts
            text_part = MIMEText(text_content, 'plain')
            html_part = MIMEText(html_content, 'html')
            msg.attach(text_part)
            msg.attach(html_part)
            
            # Attach private key if provided
            if private_key and username:
                key_filename = f"{username}_private_key"
                key_attachment = MIMEApplication(private_key, _subtype='octet-stream')
                key_attachment.add_header('Content-Disposition', 'attachment', filename=key_filename)
                msg.attach(key_attachment)
                print(f"📎 Attached private key for {username}")
            
            # Send email
            print(f"📧 Sending email to: {to_email}")
            
            if self.smtp_port == 25:
                # Port 25 - no authentication required
                with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                    server.send_message(msg)
                    print(f"✅ Email sent successfully to {to_email}")
                    return True
            else:
                # Other ports - authentication required
                with smtplib.SMTP(self.smtp_host, self.smtp_port) as server:
                    server.starttls()
                    if self.smtp_user and self.smtp_pass:
                        server.login(self.smtp_user, self.smtp_pass)
                    server.send_message(msg)
                    print(f"✅ Email sent successfully to {to_email}")
                    return True
                    
        except Exception as e:
            print(f"❌ Failed to send email to {to_email}: {e}")
            return False
    
    def send_keys_to_users(self, users_file, keys_dir, test_email=None, dry_run=False):
        """
        Send SSH keys to all users via email.
        
        Args:
            users_file (str): Path to users.yaml file
            keys_dir (str): Path to keys directory
            test_email (str): Test email address (optional)
            dry_run (bool): If True, don't actually send emails
            
        Returns:
            bool: True if all emails sent successfully, False otherwise
        """
        print("=== SSH Key Email Delivery ===")
        
        # Load users and keys
        users = self.load_users(users_file)
        keys = self.load_keys_from_directory(keys_dir)
        
        print(f"📋 Users loaded: {len(users)}")
        print(f"🔑 Keys loaded: {len(keys)}")
        print("")
        
        if dry_run:
            print("🧪 DRY RUN MODE - No emails will be sent")
            print("")
        
        success_count = 0
        total_count = len(users)
        
        for username, user_info in users.items():
            if username in keys:
                print(f"📧 Processing user: {username}")
                
                # Create email content
                html_content, text_content = self.create_email_content(
                    username, user_info, keys[username], test_email
                )
                
                # Determine recipient email
                recipient_email = test_email if test_email else user_info['email']
                
                # Create subject
                subject = f"SSH Key for EC2 Access - {username}"
                
                if not dry_run:
                    # Send email
                    if self.send_email(recipient_email, subject, html_content, text_content, keys[username], username):
                        success_count += 1
                        print(f"✅ Email sent successfully to {recipient_email}")
                    else:
                        print(f"❌ Failed to send email to {recipient_email}")
                else:
                    print(f"🧪 Would send email to: {recipient_email}")
                    print(f"   Subject: {subject}")
                    success_count += 1
                
                print("")
            else:
                print(f"⚠️  No key found for user: {username}")
                print("")
        
        # Summary
        print("=== Email Delivery Summary ===")
        print(f"Total users: {total_count}")
        print(f"Successful: {success_count}")
        print(f"Failed: {total_count - success_count}")
        
        if test_email:
            print(f"📧 All keys sent to test email: {test_email}")
        
        return success_count == total_count

def main():
    """Main function to run the SSH key emailer."""
    parser = argparse.ArgumentParser(
        description='Send SSH private keys to users via email',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Send keys to test email (port 25, no auth)
  python3 send_keys.py --smtp-host mailhost.umb.com --smtp-port 25 --keys-dir /tmp/ssh_keys --test-email saran.alla@umb.com
  
  # Send keys to actual users (port 587, with auth)
  python3 send_keys.py --smtp-host smtp.gmail.com --smtp-port 587 --smtp-user your-email@gmail.com --smtp-pass your-app-password --keys-dir /tmp/ssh_keys
  
  # Dry run mode
  python3 send_keys.py --smtp-host mailhost.umb.com --smtp-port 25 --keys-dir /tmp/ssh_keys --test-email saran.alla@umb.com --dry-run
        """
    )
    
    parser.add_argument('--users-file', default='../users.yaml', 
                       help='Path to users.yaml file (default: ../users.yaml)')
    parser.add_argument('--keys-dir', default='../keys', 
                       help='Path to keys directory (default: ../keys)')
    parser.add_argument('--smtp-host', required=True, 
                       help='SMTP server hostname')
    parser.add_argument('--smtp-user', 
                       help='SMTP username (not required for port 25)')
    parser.add_argument('--smtp-pass', 
                       help='SMTP password (not required for port 25)')
    parser.add_argument('--smtp-port', type=int, default=25, 
                       help='SMTP port (default: 25)')
    parser.add_argument('--test-email', 
                       help='Send test email to this address (optional)')
    parser.add_argument('--dry-run', action='store_true', 
                       help='Dry run mode (don\'t actually send emails)')
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.smtp_port != 25 and (not args.smtp_user or not args.smtp_pass):
        print("❌ Error: SMTP username and password are required for ports other than 25")
        sys.exit(1)
    
    if not args.test_email and args.smtp_port == 25:
        print("⚠️  Warning: Port 25 typically doesn't require authentication, but you may want to specify a test email")
    
    # Initialize emailer
    emailer = SSHKeyEmailer(args.smtp_host, args.smtp_user, args.smtp_pass, args.smtp_port)
    
    # Send keys to users
    success = emailer.send_keys_to_users(args.users_file, args.keys_dir, args.test_email, args.dry_run)
    
    if success:
        print("\n🎉 All SSH keys have been sent successfully!")
    else:
        print("\n❌ Some SSH keys failed to send. Please check the logs.")
        sys.exit(1)

if __name__ == "__main__":
    main() 