"""
Orkestra Utility Functions

Common utilities used across the system.
Replaces bash scripts from SCRIPTS/UTILS/.
"""

from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
import json
import subprocess
import logging
import shutil
import hashlib
from datetime import datetime


class FileOperations:
    """File system utilities with safety checks"""
    
    @staticmethod
    def safe_read(path: Union[str, Path], default: Optional[str] = None) -> Optional[str]:
        """
        Read file with error handling
        
        Args:
            path: File path to read
            default: Default value if file doesn't exist
            
        Returns:
            File contents or default value
        """
        try:
            with open(path, 'r') as f:
                return f.read()
        except FileNotFoundError:
            return default
        except Exception as e:
            logging.error(f"Error reading {path}: {e}")
            return default
    
    @staticmethod
    def safe_read_json(path: Union[str, Path], default: Optional[Dict] = None) -> Optional[Dict]:
        """
        Read JSON file with error handling
        
        Args:
            path: JSON file path
            default: Default value if file doesn't exist or invalid
            
        Returns:
            Parsed JSON or default value
        """
        try:
            with open(path, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            logging.error(f"Error reading JSON from {path}: {e}")
            return default if default is not None else {}
    
    @staticmethod
    def atomic_write(path: Union[str, Path], content: str):
        """
        Write file atomically to prevent corruption
        
        Args:
            path: File path to write
            content: Content to write
        """
        path = Path(path)
        temp_path = path.with_suffix(path.suffix + '.tmp')
        
        try:
            # Write to temp file
            with open(temp_path, 'w') as f:
                f.write(content)
            
            # Atomic rename
            temp_path.replace(path)
        except Exception as e:
            if temp_path.exists():
                temp_path.unlink()
            raise e
    
    @staticmethod
    def atomic_write_json(path: Union[str, Path], data: Dict, indent: int = 2):
        """
        Write JSON file atomically
        
        Args:
            path: JSON file path
            data: Data to serialize
            indent: JSON indentation
        """
        content = json.dumps(data, indent=indent)
        FileOperations.atomic_write(path, content)
    
    @staticmethod
    def backup_file(path: Union[str, Path], backup_dir: Optional[Path] = None) -> Path:
        """
        Create backup of file
        
        Args:
            path: File to backup
            backup_dir: Directory for backups (default: path.parent / 'backups')
            
        Returns:
            Path to backup file
        """
        path = Path(path)
        
        if backup_dir is None:
            backup_dir = path.parent / 'backups'
        
        backup_dir.mkdir(parents=True, exist_ok=True)
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f"{path.stem}_{timestamp}{path.suffix}"
        backup_path = backup_dir / backup_name
        
        shutil.copy2(path, backup_path)
        
        return backup_path
    
    @staticmethod
    def ensure_directory(path: Union[str, Path]) -> Path:
        """
        Ensure directory exists, create if needed
        
        Args:
            path: Directory path
            
        Returns:
            Path object for directory
        """
        path = Path(path)
        path.mkdir(parents=True, exist_ok=True)
        return path
    
    @staticmethod
    def list_files(directory: Union[str, Path], pattern: str = "*", recursive: bool = False) -> List[Path]:
        """
        List files in directory
        
        Args:
            directory: Directory to search
            pattern: Glob pattern
            recursive: Search recursively
            
        Returns:
            List of matching file paths
        """
        directory = Path(directory)
        
        if recursive:
            return list(directory.rglob(pattern))
        else:
            return list(directory.glob(pattern))
    
    @staticmethod
    def compute_checksum(path: Union[str, Path], algorithm: str = 'sha256') -> str:
        """
        Compute file checksum
        
        Args:
            path: File to checksum
            algorithm: Hash algorithm (sha256, md5, etc.)
            
        Returns:
            Hex digest of checksum
        """
        hash_func = hashlib.new(algorithm)
        
        with open(path, 'rb') as f:
            while chunk := f.read(8192):
                hash_func.update(chunk)
        
        return hash_func.hexdigest()
    
    @staticmethod
    def file_age(path: Union[str, Path]) -> float:
        """
        Get file age in seconds
        
        Args:
            path: File path
            
        Returns:
            Age in seconds
        """
        path = Path(path)
        mtime = path.stat().st_mtime
        return datetime.now().timestamp() - mtime


class GitHelpers:
    """Git operations utilities"""
    
    @staticmethod
    def is_git_repo(path: Union[str, Path]) -> bool:
        """
        Check if directory is a git repository
        
        Args:
            path: Directory to check
            
        Returns:
            True if git repo
        """
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--git-dir"],
                cwd=path,
                capture_output=True,
                text=True,
                check=False
            )
            return result.returncode == 0
        except Exception:
            return False
    
    @staticmethod
    def get_current_branch(repo_path: Union[str, Path]) -> Optional[str]:
        """
        Get active git branch
        
        Args:
            repo_path: Repository path
            
        Returns:
            Branch name or None
        """
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout.strip()
        except Exception as e:
            logging.error(f"Error getting branch: {e}")
            return None
    
    @staticmethod
    def get_recent_commits(repo_path: Union[str, Path], limit: int = 10) -> List[Dict[str, str]]:
        """
        Get recent commit history
        
        Args:
            repo_path: Repository path
            limit: Number of commits to return
            
        Returns:
            List of commit dictionaries
        """
        try:
            result = subprocess.run(
                ["git", "log", f"-{limit}", "--pretty=format:%H|%an|%ae|%at|%s"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            
            commits = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    hash, author, email, timestamp, subject = line.split('|', 4)
                    commits.append({
                        'hash': hash,
                        'author': author,
                        'email': email,
                        'timestamp': int(timestamp),
                        'subject': subject
                    })
            
            return commits
        except Exception as e:
            logging.error(f"Error getting commits: {e}")
            return []
    
    @staticmethod
    def get_changed_files(repo_path: Union[str, Path]) -> List[str]:
        """
        Get list of changed files
        
        Args:
            repo_path: Repository path
            
        Returns:
            List of changed file paths
        """
        try:
            result = subprocess.run(
                ["git", "status", "--porcelain"],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            
            files = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    # Format: "XY filename"
                    files.append(line[3:])
            
            return files
        except Exception as e:
            logging.error(f"Error getting changed files: {e}")
            return []
    
    @staticmethod
    def commit_changes(repo_path: Union[str, Path], message: str, files: Optional[List[str]] = None) -> bool:
        """
        Commit changes to git
        
        Args:
            repo_path: Repository path
            message: Commit message
            files: Specific files to commit (None = all)
            
        Returns:
            True if successful
        """
        try:
            # Add files
            if files:
                for file in files:
                    subprocess.run(
                        ["git", "add", file],
                        cwd=repo_path,
                        check=True
                    )
            else:
                subprocess.run(
                    ["git", "add", "-A"],
                    cwd=repo_path,
                    check=True
                )
            
            # Commit
            subprocess.run(
                ["git", "commit", "-m", message],
                cwd=repo_path,
                check=True
            )
            
            return True
        except Exception as e:
            logging.error(f"Error committing changes: {e}")
            return False
    
    @staticmethod
    def get_file_history(repo_path: Union[str, Path], file_path: str, limit: int = 10) -> List[Dict[str, str]]:
        """
        Get commit history for specific file
        
        Args:
            repo_path: Repository path
            file_path: File to get history for
            limit: Number of commits
            
        Returns:
            List of commits affecting file
        """
        try:
            result = subprocess.run(
                ["git", "log", f"-{limit}", "--pretty=format:%H|%at|%s", "--", file_path],
                cwd=repo_path,
                capture_output=True,
                text=True,
                check=True
            )
            
            commits = []
            for line in result.stdout.strip().split('\n'):
                if line:
                    hash, timestamp, subject = line.split('|', 2)
                    commits.append({
                        'hash': hash,
                        'timestamp': int(timestamp),
                        'subject': subject
                    })
            
            return commits
        except Exception as e:
            logging.error(f"Error getting file history: {e}")
            return []


class JSONTools:
    """JSON manipulation utilities"""
    
    @staticmethod
    def merge_json(base: Dict, updates: Dict) -> Dict:
        """
        Deep merge JSON objects
        
        Args:
            base: Base dictionary
            updates: Updates to merge in
            
        Returns:
            Merged dictionary
        """
        result = base.copy()
        
        for key, value in updates.items():
            if key in result and isinstance(result[key], dict) and isinstance(value, dict):
                result[key] = JSONTools.merge_json(result[key], value)
            else:
                result[key] = value
        
        return result
    
    @staticmethod
    def validate_schema(data: Dict, schema: Dict) -> Tuple[bool, List[str]]:
        """
        Validate JSON against schema
        
        Args:
            data: Data to validate
            schema: Schema definition
            
        Returns:
            Tuple of (is_valid, list of errors)
        """
        errors = []
        
        # Check required fields
        required = schema.get('required', [])
        for field in required:
            if field not in data:
                errors.append(f"Missing required field: {field}")
        
        # Check field types
        properties = schema.get('properties', {})
        for field, field_schema in properties.items():
            if field in data:
                expected_type = field_schema.get('type')
                actual_value = data[field]
                
                if expected_type == 'string' and not isinstance(actual_value, str):
                    errors.append(f"Field '{field}' should be string")
                elif expected_type == 'number' and not isinstance(actual_value, (int, float)):
                    errors.append(f"Field '{field}' should be number")
                elif expected_type == 'boolean' and not isinstance(actual_value, bool):
                    errors.append(f"Field '{field}' should be boolean")
                elif expected_type == 'array' and not isinstance(actual_value, list):
                    errors.append(f"Field '{field}' should be array")
                elif expected_type == 'object' and not isinstance(actual_value, dict):
                    errors.append(f"Field '{field}' should be object")
        
        return len(errors) == 0, errors
    
    @staticmethod
    def extract_path(data: Dict, path: str, default: Any = None) -> Any:
        """
        Extract value from nested JSON using dot notation
        
        Args:
            data: JSON data
            path: Dot-separated path (e.g., "user.profile.name")
            default: Default value if path not found
            
        Returns:
            Value at path or default
        """
        parts = path.split('.')
        current = data
        
        for part in parts:
            if isinstance(current, dict) and part in current:
                current = current[part]
            else:
                return default
        
        return current
    
    @staticmethod
    def set_path(data: Dict, path: str, value: Any) -> Dict:
        """
        Set value in nested JSON using dot notation
        
        Args:
            data: JSON data
            path: Dot-separated path
            value: Value to set
            
        Returns:
            Updated dictionary
        """
        parts = path.split('.')
        current = data
        
        for i, part in enumerate(parts[:-1]):
            if part not in current:
                current[part] = {}
            current = current[part]
        
        current[parts[-1]] = value
        return data
    
    @staticmethod
    def filter_keys(data: Dict, keys: List[str], exclude: bool = False) -> Dict:
        """
        Filter dictionary keys
        
        Args:
            data: Dictionary to filter
            keys: Keys to include/exclude
            exclude: If True, exclude keys instead of include
            
        Returns:
            Filtered dictionary
        """
        if exclude:
            return {k: v for k, v in data.items() if k not in keys}
        else:
            return {k: v for k, v in data.items() if k in keys}


class LoggingHelpers:
    """Logging utilities"""
    
    @staticmethod
    def setup_logger(
        name: str,
        log_file: Optional[Path] = None,
        level: int = logging.INFO,
        format_string: Optional[str] = None
    ) -> logging.Logger:
        """
        Set up a logger with file and console handlers
        
        Args:
            name: Logger name
            log_file: Optional log file path
            level: Logging level
            format_string: Custom format string
            
        Returns:
            Configured logger
        """
        logger = logging.getLogger(name)
        logger.setLevel(level)
        
        if format_string is None:
            format_string = '[%(asctime)s] %(levelname)s: %(message)s'
        
        formatter = logging.Formatter(format_string)
        
        # Console handler
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(formatter)
        logger.addHandler(console_handler)
        
        # File handler
        if log_file:
            file_handler = logging.FileHandler(log_file)
            file_handler.setFormatter(formatter)
            logger.addHandler(file_handler)
        
        return logger
    
    @staticmethod
    def log_function_call(logger: logging.Logger):
        """
        Decorator to log function calls
        
        Args:
            logger: Logger to use
            
        Returns:
            Decorator function
        """
        def decorator(func):
            def wrapper(*args, **kwargs):
                logger.debug(f"Calling {func.__name__} with args={args}, kwargs={kwargs}")
                try:
                    result = func(*args, **kwargs)
                    logger.debug(f"{func.__name__} returned {result}")
                    return result
                except Exception as e:
                    logger.error(f"{func.__name__} raised {type(e).__name__}: {e}")
                    raise
            return wrapper
        return decorator


class StringHelpers:
    """String manipulation utilities"""
    
    @staticmethod
    def truncate(text: str, max_length: int, suffix: str = "...") -> str:
        """
        Truncate string to max length
        
        Args:
            text: Text to truncate
            max_length: Maximum length
            suffix: Suffix for truncated text
            
        Returns:
            Truncated string
        """
        if len(text) <= max_length:
            return text
        return text[:max_length - len(suffix)] + suffix
    
    @staticmethod
    def slugify(text: str) -> str:
        """
        Convert text to slug format
        
        Args:
            text: Text to slugify
            
        Returns:
            Slugified string
        """
        import re
        text = text.lower()
        text = re.sub(r'[^a-z0-9]+', '-', text)
        text = text.strip('-')
        return text
    
    @staticmethod
    def format_bytes(bytes: int) -> str:
        """
        Format bytes to human-readable string
        
        Args:
            bytes: Number of bytes
            
        Returns:
            Formatted string (e.g., "1.5 MB")
        """
        for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
            if bytes < 1024.0:
                return f"{bytes:.1f} {unit}"
            bytes /= 1024.0
        return f"{bytes:.1f} PB"
    
    @staticmethod
    def format_duration(seconds: float) -> str:
        """
        Format duration to human-readable string
        
        Args:
            seconds: Duration in seconds
            
        Returns:
            Formatted string (e.g., "2h 30m")
        """
        if seconds < 60:
            return f"{seconds:.0f}s"
        elif seconds < 3600:
            minutes = seconds / 60
            return f"{minutes:.0f}m"
        elif seconds < 86400:
            hours = seconds / 3600
            minutes = (seconds % 3600) / 60
            return f"{hours:.0f}h {minutes:.0f}m"
        else:
            days = seconds / 86400
            hours = (seconds % 86400) / 3600
            return f"{days:.0f}d {hours:.0f}h"


class SystemHelpers:
    """System utilities"""
    
    @staticmethod
    def run_command(
        command: List[str],
        cwd: Optional[Path] = None,
        capture_output: bool = True,
        check: bool = False
    ) -> subprocess.CompletedProcess:
        """
        Run shell command safely
        
        Args:
            command: Command and arguments
            cwd: Working directory
            capture_output: Capture stdout/stderr
            check: Raise exception on non-zero exit
            
        Returns:
            CompletedProcess result
        """
        return subprocess.run(
            command,
            cwd=cwd,
            capture_output=capture_output,
            text=True,
            check=check
        )
    
    @staticmethod
    def get_disk_usage(path: Union[str, Path]) -> Dict[str, float]:
        """
        Get disk usage statistics
        
        Args:
            path: Path to check
            
        Returns:
            Dict with total, used, free (in GB)
        """
        stat = shutil.disk_usage(path)
        
        return {
            'total_gb': stat.total / (1024**3),
            'used_gb': stat.used / (1024**3),
            'free_gb': stat.free / (1024**3),
            'percent_used': (stat.used / stat.total) * 100
        }
    
    @staticmethod
    def find_executable(name: str) -> Optional[Path]:
        """
        Find executable in PATH
        
        Args:
            name: Executable name
            
        Returns:
            Path to executable or None
        """
        result = shutil.which(name)
        return Path(result) if result else None


class ConfigHelpers:
    """Configuration management utilities"""
    
    @staticmethod
    def load_config(config_file: Path, defaults: Optional[Dict] = None) -> Dict:
        """
        Load configuration from file with defaults
        
        Args:
            config_file: Configuration file path
            defaults: Default values
            
        Returns:
            Configuration dictionary
        """
        config = defaults.copy() if defaults else {}
        
        if config_file.exists():
            file_config = FileOperations.safe_read_json(config_file, {})
            config = JSONTools.merge_json(config, file_config)
        
        return config
    
    @staticmethod
    def save_config(config_file: Path, config: Dict):
        """
        Save configuration to file
        
        Args:
            config_file: Configuration file path
            config: Configuration dictionary
        """
        config_file.parent.mkdir(parents=True, exist_ok=True)
        FileOperations.atomic_write_json(config_file, config)
    
    @staticmethod
    def get_env_var(name: str, default: Optional[str] = None, required: bool = False) -> Optional[str]:
        """
        Get environment variable with validation
        
        Args:
            name: Variable name
            default: Default value
            required: Raise error if not found
            
        Returns:
            Variable value or default
        """
        import os
        value = os.environ.get(name, default)
        
        if required and value is None:
            raise ValueError(f"Required environment variable not set: {name}")
        
        return value
