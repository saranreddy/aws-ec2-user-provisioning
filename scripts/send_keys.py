#!/usr/bin/env python3
"""
SSH Key Email Script for AWS EC2 User Provisioning

This script sends SSH private keys to users via email after they have been
provisioned on EC2 instances. It reads user information and generated keys
from the keys directory and sends personalized emails to each user.

Requirements:
- Python 3.6+
- smtplib (built-in)
- yaml (PyYAML package)
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
            smtp_port (int): SMTP server port (default: 25)
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
            dict: Dictionary of users with username as key
        """
        try:
            with open(users_file, 'r') as f:
                data = yaml.safe_load(f)
                users = {}
                for user in data['users']:
                    users[user['username']] = user
                return users
        except Exception as e:
            print(f"❌ Error loading users from {users_file}: {e}")
            return {}
    
    def load_keys_from_directory(self, keys_dir):
        """
        Load SSH private keys from a directory.
        
        Args:
            keys_dir (str): Path to directory containing private keys
            
        Returns:
            dict: Dictionary of keys with username as key
        """
        keys = {}
        try:
            if not os.path.exists(keys_dir):
                print(f"❌ Keys directory does not exist: {keys_dir}")
                return keys
                
            for filename in os.listdir(keys_dir):
                if filename.endswith('_private_key'):
                    username = filename.replace('_private_key', '')
                    key_path = os.path.join(keys_dir, filename)
                    
                    try:
                        with open(key_path, 'r') as f:
                            key_content = f.read().strip()
                        keys[username] = key_content
                        print(f"✅ Loaded key for {username}")
                    except Exception as e:
                        print(f"⚠️  Error loading key for {username}: {e}")
                        
        except Exception as e:
            print(f"Error loading keys: {e}")
            sys.exit(1)
        
        return keys
    
    def create_email_content(self, username, user_info, private_key, instance_info=None, test_email=None):
        """
        Create email content for SSH key delivery.
        
        Args:
            username (str): Username
            user_info (dict): User information from YAML
            private_key (str): Private key content
            instance_info (dict): Instance information (optional)
            test_email (str): Test email address (optional)
            
        Returns:
            tuple: (html_content, text_content)
        """
        # Use instance info if provided, otherwise use defaults
        if not instance_info:
            instance_info = {
                'instance_id': 'EC2 Instance',
                'ip_address': 'EC2_IP_ADDRESS',
                'instance_type': 'EC2 Instance',
                'region': 'AWS Region'
            }
        
        # Determine recipient
        recipient = test_email if test_email else user_info.get('email', 'user@example.com')
        
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
                .instance-info {{ background-color: #e3f2fd; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .key-section {{ background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .warning {{ background-color: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 5px; margin: 20px 0; }}
                .footer {{ margin-top: 30px; padding-top: 20px; border-top: 1px solid #dee2e6; color: #6c757d; }}
                code {{ background-color: #f8f9fa; padding: 2px 4px; border-radius: 3px; font-family: monospace; }}
            </style>
        </head>
        <body>
            <div class="header">
                <h2>🔑 SSH Key for EC2 Access - {username}</h2>
                <p><strong>Full Name:</strong> {user_info['full_name']}</p>
                <p><strong>Generated:</strong> {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}</p>
            </div>
            
            <div class="instance-info">
                <h3>🏗️ Instance Information</h3>
                <p><strong>Instance ID:</strong> {instance_info['instance_id']}</p>
                <p><strong>IP Address:</strong> {instance_info['ip_address']}</p>
                <p><strong>Instance Type:</strong> {instance_info['instance_type']}</p>
                <p><strong>Region:</strong> {instance_info['region']}</p>
            </div>
            
            <div class="content">
                <h3>Your SSH Private Key</h3>
                <p>Your SSH private key has been generated and is attached to this email. Use this key to access your EC2 instance.</p>
                
                <div class="key-section">
                    <h4>🔐 Private Key Content</h4>
                    <pre style="background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto;">{private_key}</pre>
                </div>
                
                <div class="warning">
                    <h4>⚠️ Security Important</h4>
                    <ul>
                        <li>Keep this private key secure and never share it</li>
                        <li>Store it in ~/.ssh/ directory</li>
                        <li>Set proper permissions: chmod 600 your_key_file</li>
                        <li>Never commit private keys to version control</li>
                        <li>This key is unique to your user account</li>
                    </ul>
                </div>
                
                <h3>📋 How to Use</h3>
                <ol>
                    <li>Save the private key content above to a file (e.g., ~/.ssh/{username}_key)</li>
                    <li>Set proper permissions: <code>chmod 600 ~/.ssh/{username}_key</code></li>
                    <li>Connect to EC2: <code>ssh -i ~/.ssh/{username}_key {username}@{instance_info['ip_address']}</code></li>
                </ol>
            </div>
            
            <div class="footer">
                <p>This is an automated message from the AWS EC2 User Provisioning System.</p>
                <p>If you have any questions, please contact your system administrator.</p>
            </div>
        </body>
        </html>
        """
        
        # Create text content
        text_content = f"""SSH Key for EC2 Access - {username}
==========================================

User Information:
- Username: {username}
- Full Name: {user_info['full_name']}
- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S UTC')}

Instance Information:
- Instance ID: {instance_info['instance_id']}
- IP Address: {instance_info['ip_address']}
- Instance Type: {instance_info['instance_type']}
- Region: {instance_info['region']}

Your SSH private key has been generated and is provided below. 
Use this key to access your EC2 instance.

SECURITY IMPORTANT:
- Keep this private key secure and never share it
- Store it in ~/.ssh/ directory
- Set proper permissions: chmod 600 your_key_file
- Never commit private keys to version control
- This key is unique to your user account

Your SSH Private Key:
----------------------------------------
{private_key}
----------------------------------------

USAGE INSTRUCTIONS:
==================

Step 1: Save the Private Key
- Copy the private key above (between the dashed lines)
- Save it to a file: ~/.ssh/{username}_key
- Example: mkdir -p ~/.ssh && nano ~/.ssh/{username}_key

Step 2: Set Proper Permissions
- Set restrictive permissions: chmod 600 ~/.ssh/{username}_key
- Verify permissions: ls -la ~/.ssh/{username}_key

Step 3: Connect to EC2 Instance
- Use this command: ssh -i ~/.ssh/{username}_key {username}@{instance_info['ip_address']}
- Example: ssh -i ~/.ssh/{username}_key {username}@{instance_info['ip_address']}

Step 4: Verify Connection
- You should see a welcome message
- Run 'whoami' to confirm your username
- Run 'pwd' to see your home directory

Troubleshooting:
- If connection fails, check your private key file
- Ensure permissions are correct (chmod 600)
- Verify the instance IP address is correct
- Check if you're connecting from an allowed network

Connection Summary:
- Username: {username}
- Instance: {instance_info['instance_id']} ({instance_info['ip_address']})
- IP Address: {instance_info['ip_address']}
- SSH Command: ssh -i ~/.ssh/{username}_key {username}@{instance_info['ip_address']}

This is an automated message from the AWS EC2 User Provisioning System.
If you have any questions or need assistance, please contact your system administrator.
"""
        
        return html_content, text_content
    
    def send_email(self, to_email, subject, html_content, text_content, private_key, username):
        """
        Send email with SSH key.
        
        Args:
            to_email (str): Recipient email address
            subject (str): Email subject
            html_content (str): HTML email content
            text_content (str): Plain text email content
            private_key (str): Private key content
            username (str): Username for filename
            
        Returns:
            bool: True if email sent successfully, False otherwise
        """
        try:
            # Create message
            msg = MIMEMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = 'EC2-Provisioning <noreply@mailhost.umb.com>'
            msg['To'] = to_email
            
            # Attach text and HTML parts
            text_part = MIMEText(text_content, 'plain', 'utf-8')
            html_part = MIMEText(html_content, 'html', 'utf-8')
            msg.attach(text_part)
            msg.attach(html_part)
            
            # Attach private key as file
            key_attachment = MIMEApplication(private_key.encode('utf-8'), _subtype='txt')
            key_attachment.add_header('Content-Disposition', 'attachment', filename=f'{username}_private_key')
            msg.attach(key_attachment)
            
            # Send email
            with smtplib.SMTP(self.smtp_host, self.smtp_port, timeout=30) as server:
                # Start TLS if supported
                try:
                    server.starttls()
                    print("✅ TLS connection established")
                except:
                    print("ℹ️  TLS not supported, continuing without encryption")
                
                # Authenticate if credentials provided
                if self.smtp_user and self.smtp_pass:
                    server.login(self.smtp_user, self.smtp_pass)
                    print("✅ SMTP authentication successful")
                
                # Send email
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
        
        # Process each user
        success_count = 0
        total_count = 0
        
        for username, user_info in users.items():
            total_count += 1
            
            if username in keys:
                print(f"📧 Processing user: {username}")
                
                # Create email content
                html_content, text_content = self.create_email_content(
                    username, user_info, keys[username]
                )
                
                # Determine recipient email
                recipient_email = test_email if test_email else user_info.get('email', 'user@example.com')
                
                # Create subject
                subject = f"SSH Key for EC2 Access - {username}"
                
                if not dry_run:
                    # Send email
                    if self.send_email(recipient_email, subject, html_content, text_content, keys[username], username):
                        success_count += 1
                    else:
                        print(f"❌ Failed to send email for {username}")
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
        print(f"Total users processed: {total_count}")
        print(f"Emails sent successfully: {success_count}")
        print(f"Emails failed: {total_count - success_count}")
        print("")
        
        if success_count > 0:
            print(f"✅ SSH keys processed successfully for {success_count} users")
            if test_email:
                print(f"📧 All emails sent to test address: {test_email}")
            return True
        else:
            print("❌ No emails were processed successfully")
            return False

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
                       help='SMTP username (optional for port 25)')
    parser.add_argument('--smtp-pass', 
                       help='SMTP password (optional for port 25)')
    parser.add_argument('--smtp-port', type=int, default=25,
                       help='SMTP server port (default: 25)')
    parser.add_argument('--test-email',
                       help='Test email address (sends all emails to this address)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Dry run mode (don\'t actually send emails)')
    
    args = parser.parse_args()
    
    # Validate arguments
    if not os.path.exists(args.users_file):
        print(f"❌ Users file not found: {args.users_file}")
        sys.exit(1)
    
    if not os.path.exists(args.keys_dir):
        print(f"❌ Keys directory not found: {args.keys_dir}")
        sys.exit(1)
    
    if args.smtp_port == 25 and (args.smtp_user or args.smtp_pass):
        print("⚠️  Warning: Port 25 typically doesn't require authentication, but you may want to specify a test email")
    
    # Initialize emailer
    emailer = SSHKeyEmailer(args.smtp_host, args.smtp_user, args.smtp_pass, args.smtp_port)
    
    # Send keys to users
    success = emailer.send_keys_to_users(args.users_file, args.keys_dir, args.test_email, args.dry_run)
    
    if success:
        print("\n🎉 All SSH keys have been sent successfully!")
        sys.exit(0)
    else:
        print("\n❌ Some emails failed to send. Check the logs above.")
        sys.exit(1)

if __name__ == "__main__":
    main() 