import os
import sqlite3

def init_scriptures_db():
    output_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'database')
    os.makedirs(output_dir, exist_ok=True)
    db_path = os.path.join(output_dir, 'rlds_scriptures.db')

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute("PRAGMA journal_mode = WAL;")
    cursor.execute("PRAGMA foreign_keys = ON;")

    # 1. Inspired Version Bible Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS inspired_version_bible (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testament TEXT NOT NULL,
        book_name TEXT NOT NULL,
        chapter_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        verse_text TEXT NOT NULL,
        reference TEXT NOT NULL UNIQUE
    );
    """)

    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_iv_book_chapter 
    ON inspired_version_bible (book_name, chapter_number);
    """)

    # 2. Book of Mormon Table
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS book_of_mormon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_name TEXT NOT NULL,
        chapter_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        verse_text TEXT NOT NULL,
        reference TEXT NOT NULL UNIQUE
    );
    """)

    cursor.execute("""
    CREATE INDEX IF NOT EXISTS idx_bom_book_chapter 
    ON book_of_mormon (book_name, chapter_number);
    """)

    # 3. FTS5 Virtual Tables & Triggers
    cursor.execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS inspired_version_fts USING fts5(
        reference,
        verse_text,
        content='inspired_version_bible',
        content_rowid='id'
    );
    """)

    cursor.execute("""
    CREATE TRIGGER IF NOT EXISTS iv_ai AFTER INSERT ON inspired_version_bible BEGIN
        INSERT INTO inspired_version_fts(rowid, reference, verse_text) VALUES (new.id, new.reference, new.verse_text);
    END;
    """)

    cursor.execute("""
    CREATE VIRTUAL TABLE IF NOT EXISTS book_of_mormon_fts USING fts5(
        reference,
        verse_text,
        content='book_of_mormon',
        content_rowid='id'
    );
    """)

    cursor.execute("""
    CREATE TRIGGER IF NOT EXISTS bom_ai AFTER INSERT ON book_of_mormon BEGIN
        INSERT INTO book_of_mormon_fts(rowid, reference, verse_text) VALUES (new.id, new.reference, new.verse_text);
    END;
    """)

    # 4. Core Restoration Sample Verses
    iv_samples = [
        ('Old Testament', 'Genesis', 1, 1, 'And it came to pass that the Lord spoke unto Moses, saying: Behold, I am God Almighty, and Endless is my name.', 'Genesis 1:1'),
        ('Old Testament', 'Genesis', 7, 23, 'And the Lord called his people Zion, because they were of one heart and one mind, and dwelt in righteousness; and there was no poor among them.', 'Genesis 7:23'),
        ('Old Testament', 'Malachi', 3, 10, 'Bring all the tithes into the storehouse, that there may be food in my house, and prove me now herewith, saith the Lord of hosts.', 'Malachi 3:10'),
        ('New Testament', 'Matthew', 6, 33, 'Wherefore, seek not the things of this world, but seek ye first to build up the kingdom of God, and to establish his righteousness.', 'Matthew 6:33')
    ]

    for item in iv_samples:
        cursor.execute("""
        INSERT OR IGNORE INTO inspired_version_bible (testament, book_name, chapter_number, verse_number, verse_text, reference)
        VALUES (?, ?, ?, ?, ?, ?);
        """, item)

    bom_samples = [
        ('1 Nephi', 1, 1, 'I, Nephi, having been born of goodly parents, therefore I was taught somewhat in all the learning of my father.', '1 Nephi 1:1'),
        ('2 Nephi', 2, 25, 'Adam fell that men might be; and men are, that they might have joy.', '2 Nephi 2:25'),
        ('Mosiah', 4, 16, 'And also, ye yourselves will succor those that stand in need of your succor; ye will administer of your substance unto him that standeth in need.', 'Mosiah 4:16'),
        ('Alma', 32, 21, 'Faith is not to have a perfect knowledge of things; therefore if ye have faith ye hope for things which are not seen, which are true.', 'Alma 32:21'),
        ('Moroni', 10, 4, 'And when ye shall receive these things, I would exhort you that ye would ask God, the Eternal Father, in the name of Christ, if these things are not true.', 'Moroni 10:4')
    ]

    for item in bom_samples:
        cursor.execute("""
        INSERT OR IGNORE INTO book_of_mormon (book_name, chapter_number, verse_number, verse_text, reference)
        VALUES (?, ?, ?, ?, ?);
        """, item)

    conn.commit()
    conn.close()
    print(f"Scripture database initialized successfully at: {db_path}")

if __name__ == '__main__':
    init_scriptures_db()
