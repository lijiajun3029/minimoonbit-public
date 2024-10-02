import sys
import re
from collections import Counter
from pathlib import Path

def find_mbt_files(directory):
    """
    Recursively find all .mbt files in the given directory.

    Args:
        directory (str or Path): The directory to search.

    Returns:
        List[Path]: A list of Paths to .mbt files.
    """
    return list(Path(directory).rglob('*.mbt'))

def extract_tokens(text):
    """
    Extract words and symbols from the given text using regular expressions.

    Args:
        text (str): The text to extract tokens from.

    Returns:
        List[str]: A list of tokens.
    """
    # This regex matches words (including underscores) and programming symbols
    # Adjust the pattern if your definition of a token differs
    pattern = r'\b\w+\b|[+\-*/=<>!&|]+'
    return re.findall(pattern, text)

def count_tokens_in_files(files):
    """
    Count the occurrences of each token in the given list of files.

    Args:
        files (List[Path]): A list of Paths to files.

    Returns:
        Tuple[Counter, int]: A Counter object mapping tokens to their counts and the number of files processed.
    """
    token_counter = Counter()
    files_processed = 0

    for file_path in files:
        try:
            with file_path.open('r', encoding='utf-8') as file:
                content = file.read()
                tokens = extract_tokens(content)
                token_counter.update(tokens)
                files_processed += 1
        except Exception as e:
            print(f"Error reading {file_path}: {e}", file=sys.stderr)

    return token_counter, files_processed

def main():
    """
    Main function to execute the token counting.
    """
    # Get directory from command-line arguments or default to current directory
    if len(sys.argv) > 1:
        directory = sys.argv[1]
    else:
        directory = '.'

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
