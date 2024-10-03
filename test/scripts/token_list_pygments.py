import sys
from collections import Counter
from pathlib import Path
from pygments import lex
from pygments.lexers import get_lexer_for_filename, guess_lexer
from pygments.token import Token

def find_mbt_files(directory):
    """
    Recursively find all .mbt files in the given directory.
    """
    return list(Path(directory).rglob('*.mbt'))

def extract_tokens(file_path):
    """
    Extract tokens from a given file using Pygments.
    """
    try:
        with file_path.open('r', encoding='utf-8') as file:
            content = file.read()
            try:
                # Attempt to get a lexer based on the filename
                lexer = get_lexer_for_filename(file_path.name, content)
            except Exception:
                # Fallback to guessing the lexer
                lexer = guess_lexer(content)
            tokens = [tok[1] for tok in lex(content, lexer)]
            return tokens
    except Exception as e:
        print(f"Error reading {file_path}: {e}", file=sys.stderr)
        return []

def count_tokens_in_files(files):
    """
    Count the occurrences of each token in the given list of files.
    """
    token_counter = Counter()
    files_processed = 0

    for file_path in files:
        tokens = extract_tokens(file_path)
        if tokens:
            token_counter.update(tokens)
            files_processed += 1

    return token_counter, files_processed

def main():
    """
    Main function to execute the token counting.
    """
    # Get directory from command-line arguments or default to current directory
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'

    # Convert to Path object
    dir_path = Path(directory)

    # Verify that the directory exists
    if not dir_path.is_dir():
        print(f"Error: {directory} is not a valid directory.", file=sys.stderr)
        sys.exit(1)

    # Find all .mbt files
    mbt_files = find_mbt_files(dir_path)
    total_files = len(mbt_files)

    if total_files == 0:
        print(f"No .mbt files found in directory: {directory}")
        sys.exit(0)

    # Count tokens in all .mbt files
    token_counts, files_processed = count_tokens_in_files(mbt_files)

    if files_processed == 0:
        print("No files were successfully processed.")
        sys.exit(0)

    # Sort tokens by count in descending order
    sorted_token_counts = sorted(token_counts.items(), key=lambda x: x[1], reverse=True)

    # Print the token counts in the desired format
    for token, count in sorted_token_counts:
        print(f"{token} {count}")

    # Print the total number of files processed
    print(f"\nTotal .mbt files in {dir_path} processed: {files_processed}")

if __name__ == "__main__":
    main()
