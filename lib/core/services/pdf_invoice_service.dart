import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/invoices/models/invoice_model.dart';
import '../utils/pkr_formatter.dart';

/// PDF Invoice Builder & WhatsApp Sharing Service
class PdfInvoiceService {
  static final _emeraldPrimary = PdfColor.fromHex('#059669');
  static final _emeraldLight = PdfColor.fromHex('#ECFDF5');
  static final _emeraldDark = PdfColor.fromHex('#047857');

  /// Generates printable PDF document bytes for an InvoiceModel
  static Future<Uint8List> generateInvoicePdf(InvoiceModel invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Branding Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'AL ASAD TRADERS',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Wholesale Grain & Goods Supplier',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        'Phone: 0300 1234567 | Faisalabad, Pakistan',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: _emeraldPrimary,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '#${invoice.id.toUpperCase()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${invoice.createdAt.day}/${invoice.createdAt.month}/${invoice.createdAt.year}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 24),

              // Customer Info Block
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Billed To:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          invoice.customerName,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: 'INV:${invoice.id}|TOTAL:${invoice.grandTotalPkr}',
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Itemized PKR Pricing Table
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.symmetric(
                  inside: const pw.BorderSide(color: PdfColors.grey300),
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                headerHeight: 25,
                cellHeight: 25,
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                headers: <String>[
                  'Item Description',
                  'Unit Price (PKR)',
                  'Qty',
                  'Subtotal (PKR)'
                ],
                data: invoice.items.map((item) {
                  return <String>[
                    item.productName,
                    PkrFormatter.format(item.unitPricePkr),
                    item.quantity.toString(),
                    PkrFormatter.format(item.subtotalPkr),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),

              // Grand Total Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: _emeraldLight,
                      border: pw.Border.all(color: _emeraldPrimary, width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Grand Total:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          PkrFormatter.format(invoice.grandTotalPkr),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: _emeraldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Footer Note
              pw.Divider(thickness: 0.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Thank you for your business with Al Asad Traders!',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Computer Generated PKR Invoice',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Triggers direct print or print preview sheet
  static Future<void> printInvoice(InvoiceModel invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_${invoice.id}.pdf',
    );
  }

  /// Direct Share PDF via WhatsApp / System Share Sheet
  static Future<void> shareInvoicePdf(InvoiceModel invoice) async {
    final pdfBytes = await generateInvoicePdf(invoice);
    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/Invoice_${invoice.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);

    await Share.shareXFiles(
      [XFile(filePath)],
      text:
          'Al Asad Traders - Invoice #${invoice.id}\nCustomer: ${invoice.customerName}\nGrand Total: ${PkrFormatter.format(invoice.grandTotalPkr)}',
      subject: 'Invoice #${invoice.id} - Al Asad Traders',
    );
  }
}
