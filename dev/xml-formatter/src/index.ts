import xmlParser, {
    XmlParserElementNode,
    XmlParserNode,
    XmlParserProcessingInstructionNode,
    XmlParserDocumentChildNode,
    XmlParserElementChildNode
} from 'xml-parser-xo';

export type XMLFormatterOptions = {

    /**
     * List of XML element paths to ignore during formatting.
     * This can be a partial path (element tag name) or full path starting from the document element.
     * e.g. ['/html/head/script', 'pre']
     */
    ignoredPaths?: string[];

    /**
     * The value used for indentation.
     * Default = '    '
     */
    indentation?: string;

    /**
     * Return false to exclude the node.
     */
    filter?: (node: XmlParserNode) => boolean;

    /**
     * True to keep content in the same line as the element.
     * Notes: Only works if element contains at least one text node.
     * Default: false
     */
    collapseContent?: boolean;

    /**
     * The line separator to use.
     * Default: '\r\n'
     */
    lineSeparator?: string;

    /**
     * To either end ad self closing tag with `<tag/>` or `<tag />`.
     * Default: false
     */
    whiteSpaceAtEndOfSelfclosingTag?: boolean;

    /**
     * Throw an error when XML fails to parse and get formatted.
     * Notes: If set to `false`, the original XML is returned when an error occurs.
     * Default: true
     */
    throwOnFailure?: boolean;

    /**
     * True to throw an error when parsing XML document with invalid content like mismatched closing tags.
     */
    strictMode?: boolean;
};

export type XMLFormatterMinifyOptions = Omit<XMLFormatterOptions, 'lineSeparator'|'indentation'>;

type XMLFormatterState = {
    content: string;
    level: number;
    options: XMLFormatterOptions;
    path: string[];
};

function newLine(state: XMLFormatterState): void {
    if (!state.options.indentation && !state.options.lineSeparator) return;
    state.content += state.options.lineSeparator;
    let i;
    for (i = 0; i < state.level; i++) {
        state.content += state.options.indentation;
    }
}

function indent(state: XMLFormatterState): void {
    state.content = state.content.replace(/ +$/, '');
    let i;
    for (i = 0; i < state.level; i++) {
        state.content += state.options.indentation;
    }
}

function appendContent(state: XMLFormatterState, content: string): void {
    state.content += content;
}

function processNode(node: XmlParserNode, state: XMLFormatterState, preserveSpace: boolean): void {
    if (typeof (node as any).content === 'string') {
        processContent((node as any).content, state, preserveSpace);
    } else if (node.type === 'Element') {
        processElementNode(node as XmlParserElementNode, state, preserveSpace);
    } else if (node.type === 'ProcessingInstruction') {
        processProcessingIntruction(node as XmlParserProcessingInstructionNode, state);
    } else {
        throw new Error('Unknown node type: ' + node.type);
    }
}

function processContent(content: string, state: XMLFormatterState, preserveSpace: boolean): void {
    if (!preserveSpace) {
        const trimmedContent = content.trim();
        if (state.options.lineSeparator) {
            content = trimmedContent;
        } else if (trimmedContent.length === 0) {
            content = trimmedContent;
        }
    }
    if (content.length > 0) {
        if (!preserveSpace && state.content.length > 0) {
            newLine(state);
        }
        appendContent(state, content);
    }
}

function isPathMatchingIgnoredPaths(path: string[], ignoredPaths: string[]): boolean {
    const fullPath = '/' + path.join('/');
    const pathLastPart = path[path.length - 1];
    return ignoredPaths.includes(pathLastPart) || ignoredPaths.includes(fullPath);
}

function processElementNode(node: XmlParserElementNode, state: XMLFormatterState, preserveSpace: boolean): void {
    state.path.push(node.name);
    if (!preserveSpace && state.content.length > 0) {
        newLine(state);
    }

    appendContent(state, '<' + node.name);
    processAttributes(state, node.attributes);

    if (node.children === null) {
        const selfClosingNodeClosingTag = state.options.whiteSpaceAtEndOfSelfclosingTag ? ' />' : '/>'
        // self-closing node
        appendContent(state, selfClosingNodeClosingTag);
    } else if (node.children.length === 0) {
        // empty node
        appendContent(state, '></' + node.name + '>');
    } else {

        const nodeChildren = node.children;

        appendContent(state, '>');

        state.level++;

        let nodePreserveSpace = node.attributes['xml:space'] === 'preserve';
        let ignoredPath = false;

        if (!nodePreserveSpace && state.options.ignoredPaths) {
            ignoredPath = isPathMatchingIgnoredPaths(state.path, state.options.ignoredPaths);
            nodePreserveSpace = ignoredPath;
        }

        if (!nodePreserveSpace && state.options.collapseContent) {
            let containsTextNodes = false;
            let containsTextNodesWithLineBreaks = false;
            let containsNonTextNodes = false;

            nodeChildren.forEach(function(child: XmlParserElementChildNode, index: number) {
                if (child.type === 'Text') {
                    if (child.content.includes('\n')) {
                        containsTextNodesWithLineBreaks = true;
                        child.content = child.content.trim();
                    } else if (index === 0 || index === nodeChildren.length - 1) {
                        if (child.content.trim().length === 0) {
                            // If the text node is at the start or end and is empty, it should be ignored when formatting
                            child.content = '';
                        }
                    }
                    if (child.content.trim().length > 0) {
                        containsTextNodes = true;
                    }
                } else if (child.type === 'CDATA') {
                    containsTextNodes = true;
                } else {
                    containsNonTextNodes = true;
                }
            });

            if (containsTextNodes && (!containsNonTextNodes || !containsTextNodesWithLineBreaks)) {
                nodePreserveSpace = true;
            }
        }

        nodeChildren.forEach(function(child: XmlParserElementChildNode) {
            processNode(child, state, preserveSpace || nodePreserveSpace);
        });

        state.level--;

        if (!preserveSpace && !nodePreserveSpace) {
            newLine(state);
        }

        if (ignoredPath) {
            indent(state);
        }

        appendContent(state, '</' + node.name + '>');
    }
    state.path.pop();
}

function processAttributes(state: XMLFormatterState, attributes: Record<string, string>): void {
    Object.keys(attributes).forEach(function(attr) {
        appendContent(state, ' ' + attr + "='" + attributes[attr] + "'");
    });
}

function processProcessingIntruction(node: XmlParserProcessingInstructionNode, state: XMLFormatterState): void {
    if (state.content.length > 0) {
        newLine(state);
    }
    appendContent(state, '<?' + node.name);
    processAttributes(state, node.attributes);
    appendContent(state, '?>');
}


/**
 * Converts the given XML into human readable format.
 */
function formatXml(xml: string, options: XMLFormatterOptions = {}): string {
    options.indentation = 'indentation' in options ? options.indentation : '    ';
    options.collapseContent = options.collapseContent === true;
    options.lineSeparator = 'lineSeparator' in options ? options.lineSeparator : '\r\n';
    options.whiteSpaceAtEndOfSelfclosingTag = options.whiteSpaceAtEndOfSelfclosingTag === true;
    options.throwOnFailure = options.throwOnFailure !== false;

    try {
        const parsedXml = xmlParser(xml, {filter: options.filter, strictMode: options.strictMode});
        const state = {content: '', level: 0, options: options, path: []};

        if (parsedXml.declaration) {
            processProcessingIntruction(parsedXml.declaration, state);
        }

        parsedXml.children.forEach(function (child: XmlParserDocumentChildNode) {
            processNode(child, state, false);
        });

        if (!options.lineSeparator) {
            return state.content;
        }

        return state.content
            .replace(/\r\n/g, '\n')
            .replace(/\n/g, options.lineSeparator as string);
    } catch (err) {
        if (options.throwOnFailure) {
            throw err;
        }
        return xml;
    }
}

formatXml.minify = (xml: string, options: XMLFormatterMinifyOptions = {}) => {
    return formatXml(xml, {...options, indentation: '', lineSeparator: ''});
}

if (typeof module !== 'undefined' && typeof exports === 'object') {
    module.exports = formatXml;
}

export default formatXml;
