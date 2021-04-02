#!/usr/bin/env python3

from argparse import ArgumentParser
import hashlib
import json
from pathlib import Path
import re
import sys
from urllib.parse import urlparse


class Anonymizer(object):
    """Walk a builtin python data structure, anonymizing PII as we go."""

    key_rules = ["title", "name", "phone"]
    value_rules = ["http", "@"]
    # noqa: E501 h/t https://stackoverflow.com/questions/17681670/extract-email-sub-strings-from-large-document/17681902
    addr_regex = r"[\w\.-]+@[\w\.-]+\.\w+"
    # noqa: E501 h/t https://stackoverflow.com/questions/520031/whats-the-cleanest-way-to-extract-urls-from-a-string-using-python
    url_regex = re.compile(
        r"(?i)\b((?:https?:(?:/{1,3}|[a-z0-9%])|[a-z0-9.\-]+[.]"
        r"(?:com|net|org|edu|gov|mil|aero|asia|biz|cat|coop|info|"
        r"int|jobs|mobi|museum|name|post|pro|tel|travel|xxx|ac|ad|"
        r"ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|"
        r"be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cd|"
        r"cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cs|cu|cv|cx|cy|cz|dd|de|dj|"
        r"dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|"
        r"gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|"
        r"hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|je|jm|jo|jp|"
        r"ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|"
        r"lu|lv|ly|ma|mc|md|me|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|"
        r"mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|"
        r"pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|"
        r"rw|sa|sb|sc|sd|se|sg|sh|si|sj|Ja|sk|sl|sm|sn|so|sr|ss|st|"
        r"su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|"
        r"tv|tw|tz|ua|ug|uk|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|"
        r"yt|yu|za|zm|zw)/)(?:[^\s()<>{}\[\]]+|\([^\s()]*?\([^\s()]"
        r"+\)[^\s()]*?\)|\([^\s]+?\))+(?:\([^\s()]*?\([^\s()]+\)["
        r"^\s()]*?\)|\([^\s]+?\)|[^\s`!()\[\]{};:\'\".,<>?«»“”‘’])|"
        r"(?:(?<!@)[a-z0-9]+(?:[.\-][a-z0-9]+)*[.](?:com|net|org|edu|"
        r"gov|mil|aero|asia|biz|cat|coop|info|int|jobs|mobi|museum|name|"
        r"post|pro|tel|travel|xxx|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|"
        r"ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|"
        r"br|bs|bt|bv|bw|by|bz|ca|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|"
        r"cr|cs|cu|cv|cx|cy|cz|dd|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|"
        r"es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|"
        r"gn|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|"
        r"in|io|iq|ir|is|it|je|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|"
        r"ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|"
        r"mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|"
        r"nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|"
        r"pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|"
        r"sj|Ja|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|"
        r"th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|us|uy|uz|"
        r"va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)\b/?(?!@)))"
    )

    def anonymize(self, an_obj):
        if isinstance(an_obj, dict):
            self.anonymize_dict(an_obj)
        elif isinstance(value, set):
            self.anonymize_set(value)
        elif isinstance(object, list) or isinstance(an_obj, tuple):
            self.anonymize_indexed(an_obj)

    def anonymize_dict(self, a_dict):
        for key, value in a_dict.items():
            if isinstance(value, dict):
                self.anonymize_dict(value)
            elif isinstance(value, set):
                self.anonymize_set(value)
            elif isinstance(value, list) or isinstance(value, tuple):
                self.anonymize_indexed(value)
            elif isinstance(value, str):
                a_dict[key] = self.anonymize_item(key, value)

    def anonymize_set(self, a_set):
        for elem in a_set:
            if isinstance(elem, dict):
                self.anonymize_dict(elem)
            elif isinstance(elem, set):
                self.anonymize_set(elem)
            elif isinstance(elem, list) or isinstance(elem, tuple):
                self.anonymize_indexed(elem)
            elif isinstance(elem, str):
                a_set.add(self.anonymize_str(elem))
                a_set.remove(elem)

    def anonymize_indexed(self, an_arr):
        for idx, elem in enumerate(an_arr):
            if isinstance(elem, dict):
                self.anonymize_dict(elem)
            elif isinstance(elem, set):
                self.anonymize_set(elem)
            elif isinstance(elem, list):
                self.anonymize_array(elem)
            elif isinstance(elem, str):
                an_arr[idx] = self.anonymize_str(elem)

    def anonymize_item(self, key, value):
        if any(word in key for word in self.key_rules):
            return self.anonymize_str(value, True)
        return self.anonymize_str(value)

    def anonymize_str(self, str, whole_str=False):
        new_str = str
        if whole_str == True:
            new_str = self.hash_str(str)
        else:
            if any(word in str for word in self.value_rules):
                for url in re.findall(self.url_regex, str):
                    new_str = new_str.replace(url, self.hash_url(url))
                for addr in re.findall(self.addr_regex, str):
                    name, domain = addr.split("@")
                    new_str = new_str.replace(name, self.hash_str(name))
        return new_str

    def hash_url(self, url):
        path = urlparse(url).path
        if path[0] == '/':
            path = path[1:]
        new_url = url.replace(path, self.hash_str(path))
        return new_url

    def hash_str(self, str):
        md5 = hashlib.md5()
        md5.update(str.encode("utf-8"))
        return md5.hexdigest()


def main():
    """The main thing."""
    parser = ArgumentParser(description="Anonymize PII in a JSON file.")
    parser.add_argument("input_file", help="A JSON file to anonymize")
    parser.add_argument(
        "output_file",
        nargs="?",
        help="File to write anonymized data to (Default: <input_file>)",
    )
    args = parser.parse_args()
    input_file = args.input_file
    output_file = args.output_file if args.output_file is not None else input_file

    with open(input_file, mode="rt", encoding="utf-8") as ifh:
        data = json.load(ifh)

    anonymizer = Anonymizer()
    anonymizer.anonymize(data)

    with open(output_file, mode="wt", encoding="utf-8") as ofh:
        ofh.write(json.dumps(data, indent=4))


if __name__ == "__main__":
    main()
