#!/usr/bin/env python3
"""
Orkestra - Multi-AI Task Coordination Platform
Setup script for PyPI distribution
"""

from setuptools import setup, find_packages
import os

# Read the long description from README
def read_file(filename):
    with open(os.path.join(os.path.dirname(__file__), filename), encoding='utf-8') as f:
        return f.read()

setup(
    name='orkestra-ai',
    version='1.0.0',
    description='Multi-AI Task Coordination Platform - Orchestrate Claude, ChatGPT, Gemini, Copilot, and Grok',
    long_description=read_file('README.md'),
    long_description_content_type='text/markdown',
    author='hendrixx-cnc',
    author_email='contact@example.com',  # Update with your email
    url='https://github.com/hendrixx-cnc/Orkestra',
    license='Apache-2.0',
    
    packages=find_packages(where='src'),
    package_dir={'': 'src'},
    
    # Include non-Python files
    include_package_data=True,
    package_data={
        'orkestra': [
            'templates/**/*',
            'templates/**/**/*',
            'scripts/**/*.sh',
            'scripts/**/**/*.sh',
            'config/**/*.json',
            'config/**/*.env.example',
        ],
    },
    
    # Python version requirement
    python_requires='>=3.8',
    
    # Dependencies
    install_requires=[
        'click>=8.0.0',
        'rich>=10.0.0',
        'pyyaml>=5.4.0',
        'jinja2>=3.0.0',
        'python-dotenv>=0.19.0',
    ],
    
    # Optional dependencies
    extras_require={
        'dev': [
            'pytest>=7.0.0',
            'pytest-cov>=3.0.0',
            'black>=22.0.0',
            'flake8>=4.0.0',
            'mypy>=0.950',
        ],
    },
    
    # CLI entry point
    entry_points={
        'console_scripts': [
            'orkestra=orkestra.cli:main',
        ],
    },
    
    # Classifiers for PyPI
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: Apache Software License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
        'Operating System :: OS Independent',
        'Topic :: Software Development :: Libraries :: Application Frameworks',
        'Topic :: System :: Distributed Computing',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
    ],
    
    keywords='ai orchestration multi-agent coordination claude chatgpt gemini copilot grok automation workflow',
    
    project_urls={
        'Bug Reports': 'https://github.com/hendrixx-cnc/Orkestra/issues',
        'Source': 'https://github.com/hendrixx-cnc/Orkestra',
        'Documentation': 'https://github.com/hendrixx-cnc/Orkestra/tree/main/DOCS',
    },
)
