/*
 * Generated by asn1c-0.9.28 (http://lionet.info/asn1c)
 * From ASN.1 module "ROSTER"
 * 	found in "/Users/proger/cg/chat/src/ROSTER.asn1"
 */

#ifndef	_Sub_H_
#define	_Sub_H_


#include <asn_application.h>

/* Including external dependencies */
#include <OCTET_STRING.h>
#include "Adr.h"
#include <constr_SEQUENCE.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Sub */
typedef struct Sub {
	OCTET_STRING_t	 key;
	Adr_t	 adr;
	
	/* Context for parsing across buffer boundaries */
	asn_struct_ctx_t _asn_ctx;
} Sub_t;

/* Implementation */
extern asn_TYPE_descriptor_t asn_DEF_Sub;

#ifdef __cplusplus
}
#endif

#endif	/* _Sub_H_ */
#include <asn_internal.h>
